-- comms for the addon network
-- CHAT_MSG_ADDON

local addonName, addonData = ...
local L = LibStub("AceLocale-3.0"):GetLocale("SteaSummon")

-- protocol
-----------
-- a arrived
-- ad add player
-- c clicks
-- d destination
-- i initialize me
-- l waiting list
-- s status
-- netreq request network list
-- netlist network list
-- e election
-- adrec add a record
-- atD player at destination
-- retire retire from network
-- edone election result
-- v old version
-- version SteaSummon version Broadcast
-- alt alt list for player
-- wsp player alt whispered
-- n nags
-- ct

local DEFAULT_NETLIST_TIME = 15


local gossip = {
  channel = "SteaSummon",
  netlistTimer = nil,
  tmpOps = {},
  netList = {},
  inInit = true,
  atDest = {},
  atDestCount = 0,
  atDestTimer = nil,
  me = nil,
  recvElections = 0,
  votes = 0,
  version = nil, -- the net protocol version
  versionBad = false,
  votingBooth = {},
  SSversion = 0,
  SSversion_notified = false,
  replayLog = {},
  destLocks = {},
  destClicks = {},
  locksCount = 0,
  adjClicks = 0,
  adjLocks = 0,
  raidInfoTimer = nil,
  clickersNagTimer = nil,
  inRaid = false,


  ---------------------------------
  init = function(self)
    addonData.debug:registerCategory("gossip.event")
    -- register addon comms channel
    self:RegisterComm(self.channel, "callback")
    -- RegisterComm never returns anything, not good imo
    self.me, _ = UnitName("player")
    self.votes = UnitGUID("player")
    self.version = GetAddOnMetadata(addonName, "x-SteaSummon-Protocol-version")
    self.SSversion = tonumber(GetAddOnMetadata(addonName, "Version"))
  end,

  ---------------------------------
  groupText = function(_)
    if IsInRaid() then
      return "RAID"
    else
      return "PARTY"
    end
  end,

  ---------------------------------
  netOn = function(self, on)
    if on == nil or on then
      if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        self:raidJoined()
      end
    else
      self:retire()
      self:raidLeft()
    end
  end,

  ---------------------------------
  retire = function(self)
    if IsInGroup(LE_PARTY_CATEGORY_HOME) then
      db("gossip", ">> retire >>", self:groupText())
      self:SendCommMessage(self.channel, "retire", self:groupText())
    end
  end,

  ---------------------------------
  netListTimeout = function(self)
    self = addonData.gossip
    if self.inInit then
      db("gossip", "TIMED OUT waiting for netlist")
      self.inInit = false
      db("gossip", ">> election over >>")
      self:SendCommMessage(self.channel, "edone", self:groupText(), "ALERT")
      self:postInit()
    end
  end,

  ---------------------------------
  postInit = function(self)
    table.sort(self.votingBooth)
    wipe(self.netList)
    for _,v in pairs(self.votingBooth) do
      local _, _, _, _, _, name = GetPlayerInfoByGUID(v)
      db("gossip", "netlist:", name)
      if not addonData.util:isInTable(self.netList, name) then
        table.insert(self.netList, name)
      end
    end

    if not self:isLeader() then
      self:initialize()
    else
      self:replayMessageLog(self.replayLog)
    end
  end,

  ---------------------------------
  replayMessageLog = function(self, log)
    for _,v in pairs(log) do
      db("gossip", "replaying", v[1], "from", v[2])
      self:receive(v[1], nil, v[2])
    end
  end,

  ---------------------------------
  noComms = function(self)
    return self.versionBad or not addonData.settings:useUpdates()
  end,

  ---------------------------------
  netListSend = function(self, player)
    if self:noComms() then
      return
    end

    local msg = "netlist " .. addonData.util:tableToMultiLine(self.netList, "\n")
    db("gossip", ">> netlist send >> WHISPER", player)
    self:SendCommMessage(self.channel, msg, "WHISPER", player)
  end,

  ---------------------------------
  raidJoined = function(self)
    if self:noComms() then
      return
    end

    if self.inInit and not self.versionBad and not self.inRaid then
      db("gossip", "group joined")
      self.inRaid = true
      -- 1. On first raidJoin, request network list
      db("gossip", ">> netreq >>", self:groupText())
      self:SendCommMessage(self.channel, "netreq ".. self.votes.. "+"
          .. self.version, self:groupText(), "ALERT")
      -- 3. if not received, you are the first one on the list and network leader
      table.insert(self.votingBooth, 1, self.votes)
      self.netlistTimer = C_Timer.NewTimer(DEFAULT_NETLIST_TIME, self.netListTimeout)
      -- make ourselves leader temporarily so we can replay messages to the leader when network established
      table.insert(self.netList, 1, self.me)
      if SteaSummonSave.raidinfotimer then
        self.raidInfoTimer = addonData.monitor:create(SteaSummonSave.raidinfotimer * 60, self.raidInfo, false)
      end
      if SteaSummonSave.clickersnagtimer then
        self.clickersNagTimer = addonData.monitor:create(SteaSummonSave.clickersnagtimer * 60, self.clickerNag, false)
      end
      self:SteaSummonVersion()
    end
  end,

  ---------------------------------
  summonQuorum = function(self)
    return ((self.adjLocks and self.adjLocks + self.adjClicks > 2) or
          (self.locksCount and self.atDestCount - self.locksCount > 2))
  end,

  ---------------------------------
  raidInfo = function(self)
    self = addonData.gossip

    if addonData.summon.infoSend and not self.inInit and IsInGroup(LE_PARTY_CATEGORY_HOME) and self:isLeader() and
      self:summonQuorum() and addonData.summon.zone ~= ""
    then
      self:chatThis("raidinfo")
    end

    if SteaSummonSave.raidinfotimer then
      self.raidInfoTimer = addonData.monitor:create(SteaSummonSave.raidinfotimer * 60, self.raidInfo, false)
    end
  end,

  ---------------------------------
  clickerNag = function(self)
    self = addonData.gossip

    if addonData.summon.infoSend and not self.inInit and IsInGroup(LE_PARTY_CATEGORY_HOME) and self:isLeader() and
        not self:summonQuorum() and addonData.summon.zone ~= ""
    then
      db("gossip", "clicker nag")
      self:chatThis("moreclicks")
    end

    if SteaSummonSave.clickersnagtimer then
      self.clickersNagTimer = addonData.monitor:create(SteaSummonSave.clickersnagtimer * 60, self.clickerNag, false)
    end
  end,

  ---------------------------------
  offlineCheck = function(self)
    local killList = {}
    for i,v in pairs(self.netList) do
      if not UnitIsConnected(v) then
        table.insert(killList, 1, i)
        db("gossip", v, "is offline without notification, removing from list pos", i)
      end
    end

    for _, v in pairs(killList) do
      table.remove(self.netList, v)
      local at = self.atDest[v]
      self.atDest[v] = nil
      if at then
        self:updateCounts(false, v)
      end
      if self.locksCount == 0 and self.adjLocks == 0 then
        addonData.summon:setDestination("","")
        self:clicks(0,0)
      end
    end
  end,

  ---------------------------------
  raiderLeft = function(self, player)
    if self:noComms() then
      return
    end

    -- 8. when someone goes offline or leaves raid that is in the list, remove their name, you may become leader
    for i,v in pairs(self.netList) do
      if v == player then
        db("gossip", player, "left net group")
        table.remove(self.netList, i)
        break
      end
    end

    if self.inInit then
      for i,v in pairs(self.votingBooth) do
        local _, _, _, _, _, name = GetPlayerInfoByGUID(v)
        if name == player then
          db("gossip", player, "left net group")
          table.remove(self.votingBooth, i)
          break
        end
      end
    end

    local at = self.atDest[player]
    self.atDest[player] = nil
    if at then
      self:updateCounts(false, player)
    end
    if self.locksCount == 0 and self.adjLocks == 0 then
      addonData.summon:setDestination("","")
      self:clicks(0,0)
    end
  end,

  ---------------------------------
  raidLeft = function(self)
    db("gossip", "You left net group")
    if self.netlistTimer and not self.netlistTimer:IsCancelled() then
      self.netlistTimer:Cancel()
    end
    addonData.summon:listClear()
    self.inRaid = false
    self.recvElections = 0
    self.inInit = true
    wipe(self.netList)
    self.votingBooth = {}
    wipe(self.atDest)
    self.atDestCount = 0
    wipe(self.replayLog)
    wipe(self.destLocks)
    wipe(self.destClicks)
    self.locksCount = 0
    addonData.summon:setClicks(0,0)
    addonData.summon:setDestination("","")
  end,

  ---------------------------------
  isLeader = function(self)
    if self:noComms() then
      return true
    elseif self.inInit then
      return false
    end

    self:offlineCheck() -- we may have become the leader

    return self.netList[1] == self.me
  end,

  ---------------------------------
  nag = function(self, set)
    if set then
      set = "true"
    else
      set = "false"
    end
    if self:isLeader() then
      db("gossip", ">> nag >>", self:groupText(), set)
      self:SendCommMessage(self.channel, "n " .. set, self:groupText(), self.netList[1])
    else
      db("gossip", ">> nag >> WHISPER", set)
      self:SendCommMessage(self.channel, "n " .. set, "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  chatThis = function(self, msgtype, target, youDoIt)
    -- unlike other messages that either go to raid when leader or whisper to leader
    -- this one goes from leader to someone else, unless someone else can't be found
    if youDoIt or addonData.util:playerCanSummon() then
      if msgtype == "alt" then
        addonData.chat:whisper(SteaSummonSave.altWhisper, target)
      elseif msgtype == "raisealt" then
        addonData.chat:whisper(SteaSummonSave.altGetOnlineWhisper, target)
      else
        db("gossip", "raid chat this", msgtype, target)
        local msg = ""
        if msgtype == "moreclicks" then
          msg = SteaSummonSave.clickersnag
          db("gossip", "clicker nag")
        elseif msgtype == "raidinfo" then
          msg = SteaSummonSave.raidinfo
          db("gossip", "raid info")
        else
          return -- no msgtype, no message
        end

        local z, l = addonData.summon:getDestination()
        local patterns = {
          ["%%l"] = l,
          ["%%z"] = z
        }

        if z and z ~= "" and l and l ~= "" then
          msg = tstring(msg, patterns)
          addonData.chat:raid(msg, self.me)
        end
      end
    else
      -- find someone more appropriate, like a warlock with the addon, task authority matters
      local theOne
      if self.destLocks[1] ~= nil then
        theOne = self.destLocks[1]
      else
        for _,v in pairs(self.netList) do
          if addonData.util:playerCanSummon(v) then
            theOne = v
            break
          end
        end
      end

      if not theOne then
        self:chatThis(msgtype, target, true) -- Neo's not here, so it's up to you
      else
        db("gossip", ">> chat this >> WHISPER", theOne, msgtype, target)
        if not target then
          target = ""
        end
        self:SendCommMessage(self.channel, "ct " ..  " " .. msgtype .. " " .. target, "WHISPER", theOne)
      end
    end
  end,

  ---------------------------------
  status = function(self, player, status)
    if self:isLeader() then
      local idx = addonData.summon:findWaitingPlayerIdx(player)
      if idx then
        if addonData.summon:recStatus(addonData.summon.waiting[idx]) ~= status then
          addonData.summon:recStatus(addonData.summon.waiting[idx], status)
          if self:noComms() then
            return
          end
          db("gossip", ">> status >> ", self:groupText(), player, status)
          self:SendCommMessage(self.channel, "s " .. player .. "+" .. status, self:groupText())
          if status == "offline" then
            self.atDest[player] = nil
            self:updateCounts(false, player)
          end
          if addonData.summon.needBoost then
            addonData.alt:listBoost()
          end
        end
      end
    else
      if self:noComms() then
        return
      end
      db("gossip", ">> status >> WHISPER", player, status)
      self:SendCommMessage(self.channel, "s " .. player .. "+" .. status, "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  arrived = function(self, player, cancel)
    local cancelText = "true"

    if cancel == nil then
      cancel = true
    end

    if not cancel then
      cancelText = "false"
    end

    if self:isLeader() then
      if addonData.summon:findWaitingPlayerIdx(player) then
        addonData.summon:arrived(player, cancel)
        if self:noComms() then
          return
        end
        db("gossip", ">> arrived >>", self:groupText(), player, cancel)
        self:SendCommMessage(self.channel, "a " .. player .. " " .. cancelText, self:groupText())
        addonData.alt:listShorter()
      end
    else
      if self:noComms() then
        return
      end
      db("gossip", ">> arrived >> WHISPER", self.netList[1], player)
      self:SendCommMessage(self.channel, "a " .. player .. " ".. cancelText, "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  add = function(self, player, isWhisper)
    if self:isLeader() then
      local index = addonData.summon:findWaitingPlayerIdx(player)
      if not index then
        addonData.summon:addWaiting(player)
        if self:noComms() then
          return
        end
        local idx = addonData.summon:findWaitingPlayerIdx(player)
        local rec = addonData.summon:recMarshal(addonData.summon.waiting[idx])
        db("gossip", ">> adrec >>", self:groupText(), player)
        self:SendCommMessage(self.channel, "adrec " .. tostring(idx) .. "_" .. rec, self:groupText())
        addonData.alt:newPlayer(player)
      else
        addonData.summon:addWaiting(player, true)
        self:status(player, "requested")
      end
      addonData.alt:askForAlts(player)
    else
      if self:noComms() then
        return
      end
      if isWhisper or self.inInit then
        db("gossip", ">> add >> WHISPER", self.netList[1], player)
        self:SendCommMessage(self.channel, "ad " .. player, "WHISPER", self.netList[1])
      end
    end
  end,

  ---------------------------------
  alts = function(self, player, playeralts)
    local alts

    if self:isLeader() then
      local rec = addonData.summon:findWaitingPlayer(player)
      if rec then
        local mergedAlts = addonData.summon:recMergeAlts(rec, playeralts)
        for _, v in pairs(mergedAlts) do
          db("gossip", v)
        end
        alts = addonData.summon:marshallAlts(mergedAlts)
        db("gossip", alts)

        if self:noComms() then
          return
        end

        db("gossip", ">> alt >>", self:groupText(), player, alts)
        self:SendCommMessage(self.channel, "alt " .. player .. "+" .. alts, self:groupText())
      end
    else
      if self:noComms() then
        return
      end
      alts = addonData.summon:marshallAlts(playeralts)
      db("gossip", ">> alts >> WHISPER", self.netList[1], player, alts)
      self:SendCommMessage(self.channel, "alt " .. player .. "+" .. alts, "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  altWhispered = function(self, player, alt)
    local rec = addonData.summon:findWaitingPlayer(player)

    if self:isLeader() and rec then
      self:SendCommMessage(self.channel, "wsp " .. player .. "+" .. alt, self:groupText())
    else
      self:SendCommMessage(self.channel, "wsp " .. player .. "+" .. alt, "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  destination = function(self, zone, location, noSet, player)
    local destination = string.gsub(zone .. "+" .. location, " ", "_")

    if not player and self:isLeader() then
      if addonData.summon.zone ~= zone or addonData.summon.location ~= location then
        db("gossip", ">> destination >>", self:groupText(), destination)
        self:wipeCounts()

        if self:noComms() then
          return
        end

        self:SendCommMessage(self.channel, "d " .. destination, self:groupText())
        if not noSet then
          addonData.summon:setDestination(zone,location)
          if zone == "" then
            self:wipeCounts()
          end
        end
      end
    else
      if self:noComms() then
        return
      end
      if not player then
        player = self.netList[1]
        self:wipeCounts()
      end
      db("gossip", ">> destination >> WHISPER", player, destination)
      self:SendCommMessage(self.channel, "d " .. destination, "WHISPER", player)
    end
  end,

  ---------------------------------
  wipeCounts = function(self)
    self.atDestCount = 0
    self.locksCount = 0
    self.adjLocks = 0
    self.adjClicks = 0
    wipe(self.atDest)
    wipe(self.destLocks)
    wipe(self.destClicks)
    addonData.summon:setClicks(0, 0)
  end,

  ---------------------------------
  updateCounts = function(self, at, name)
    local summonTest
    if name == nil or name == "" then
      return
    end
    if name == self.me then
      summonTest = "player"
    else
      summonTest = name
    end
    if at then
      self.atDestCount = self.atDestCount + 1
      if addonData.util:playerCanSummon(summonTest) then
        self.destLocks[name] = true
        self.locksCount = self.locksCount + 1
      else
        self.destClicks[name] = true
      end
    else
      self.atDestCount = self.atDestCount - 1
      if addonData.util:playerCanSummon(summonTest) then
        self.destLocks[name] = nil
        self.locksCount = self.locksCount - 1
      else
        self.destClicks[name] = nil
      end
    end
    db('gossip', "count", name, "locks", self.locksCount, "clicks", self.atDestCount - self.locksCount, "total", self.atDestCount)
    self:setClicks()
  end,

  ---------------------------------
  setClicks = function(self, locks, clickers, noSend)
    local locksCount = self.locksCount
    local clicksCount = self.atDestCount - self.locksCount

    if locks ~= nil and clickers ~= nil then
      self.adjClicks = clickers
      self.adjLocks = locks
      addonData.summon:setClicks(locks, clickers)
      return
    end

    if addonData.summon:isAtDestination() then
      local fished = addonData.raid:fishedClickers()
      for _,v in pairs(fished) do
        if self.atDest[v] == nil then
          if addonData.util:playerCanSummon(v) then
            locksCount = locksCount + 1
          else
            clicksCount = clicksCount + 1
          end
        end
      end
      db('gossip', "fished adjusted count: locks", locksCount, "clicks", clicksCount, "total", locksCount + clicksCount)
      self.adjLocks = locksCount
      self.adjClicks = clicksCount
      if not self:isLeader() then
        self:clicks(locksCount, clicksCount)
      end
    end

    if self:isLeader() and not noSend then
      self:clicks(self.adjLocks, self.adjClicks)
    end
  end,

  ---------------------------------
  clicks = function(self, locks, clickers)
    if self:isLeader() then
      self.adjClicks = clickers
      self.adjLocks = locks

      db("gossip", ">> clickers >>", self:groupText(), locks, clickers)
      if not self:noComms() then
        self:SendCommMessage(self.channel, "c " .. locks .. "+" .. clickers, self:groupText())
      end
      self:setClicks(locks, clickers)
    else
      if self:noComms() then
        return
      end
      db("gossip", ">> clickers >> WHISPER", self.netList[1], locks, clickers)
      self:SendCommMessage(self.channel, "c " .. locks .. "+" .. clickers, "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  getCounts = function(self)
    return self.atDestCount, self.locksCount, self.atDestCount - self.locksCount
  end,

  ---------------------------------
  atDestination = function(self, at, name)
    if self:isLeader() then
      local settingSelf = false
      if not name then
        name = self.me
        settingSelf = true
      end

      if (self.atDest[name] == nil and at) or (self.atDest[name] and not at) then
        db("gossip", name, "at destination:", self.atDest[name], "adding:", at)
        self.atDest[name] = at or nil

        if self:noComms() then
          if self.atDestCount == 0 then
            self:destination("", "") -- you have moved on
          end
          return
        end

        self:updateCounts(at, name)

        if self.atDestCount == 0 then
          self:destination("", "") -- the raid has moved on
        else
          db("gossip", ">> atDestination >>", self:groupText(), name, at)
          self:SendCommMessage(self.channel, "atD " .. name .. "+" .. tostring(at), self:groupText())
        end
      end

      db("gossip", "at destination count:", self.atDestCount)

    else -- not leader
      if self:noComms() then
        return
      end
      db("gossip", ">> atDestination >> WHISPER", self.netList[1], at)
      self:SendCommMessage(self.channel, "atD " .. self.me .. "+" .. tostring(at), "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  initialize = function(self)
    if self == nil then
      self = addonData.gossip
    end
    if self:noComms() then
      return
    end

    self:offlineCheck()
    local target = self.netList[1]
    if self:isLeader() then -- can happen on /reload
      target = self.netList[2]
    end
    db("gossip", ">> initialize >> WHISPER", target)

    self:SendCommMessage(self.channel, "i", "WHISPER", target)
  end,

  ---------------------------------
  SteaSummonVersion = function(self, to)
    if self:noComms() then
      return
    end
    if to then
      db("gossip", ">> version >> Informing", to, "they have an old version")
      self:SendCommMessage(self.channel, "version " .. tostring(self.SSversion), "WHISPER", to)
    else
      db("gossip", ">> requesting version >>")
      if IsInRaid() then
        self:SendCommMessage(self.channel, "version " .. tostring(self.SSversion), "RAID")
      else
        self:SendCommMessage(self.channel, "version " .. tostring(self.SSversion), "GUILD")
      end
    end
  end,

  ---------------------------------
  callback = function(self, prefix, msg, dist, sender, ... )
    if prefix ~= self.channel then
      return
    end
    --db("gossip.event", "prefix:", prefix, "msg:", msg, "dist:", dist, "sender:", sender, ...)
    if self:noComms() then
      return
    else
      if sender ~= self.me or self.inInit then
        addonData.gossip:receive(msg, dist, sender, ... )
      end
    end
  end,

  ---------------------------------
  receive = function(self, msg, dist, sender, ... )
    local cmd, subcmd = strsplit(" ", msg, 2)
    local okForInit = {
      ["netlist"] = 1,
      ["e"] = 1,
      ["edone"] = 1,
      ["version"] = 1,
      ["netreq"] = 1,
      ["retire"] = 1,
      ["v"] = 1}

    db ("gossip.event", "message", cmd, "from", sender, "channel", dist, "payload:", subcmd)

    local function senderIsLeader()
      if self.inInit then
        return false
      end
      return sender == self.netList[1]
    end

    -- While we are in init things don't stop happening, but we are not in a position
    -- to properly respond to those things yet, so we store messages other than those
    -- pertinent to init and we replay those later once we are properly initialized
    -- e.g. we might end up being leader and have to initialize others, or a summon
    -- request could come in while we don't know who is leader, or instructions to
    -- change the status for someone in a waiting list we don't have yet
    if self.inInit and not okForInit[cmd] then
      db("gossip", "adding replay log entry:", msg, sender)
      table.insert(self.replayLog, {msg, sender})
      return
    end

    --- arrive
    if cmd == "a" then
      db("gossip", "<< arrived <<", subcmd)
      local player, cancel = strsplit(" ", subcmd)

      if cancel == "true" then
        cancel = true
      else
        cancel = false
      end

      if self:isLeader() then
        self:arrived(player, cancel)
      else
        addonData.summon:arrived(player, cancel)
      end

      --- add player
    elseif cmd == "ad" then
      db("gossip", "<< add <<", subcmd)
      if self:isLeader() then
        self:add(subcmd)
      end

      --- add record
    elseif cmd == "adrec" then
      if not senderIsLeader() then return end

      local i, rec = strsplit("_", subcmd)
      db("gossip", "<< add record <<", rec)
      local ununmarshalledRec = addonData.summon:recUnMarshal(rec)
      if not addonData.summon:findWaitingPlayer(addonData.summon:recPlayer(ununmarshalledRec)) then
        addonData.summon:recAdd(ununmarshalledRec, tonumber(i))
        addonData.alt:newPlayer(addonData.summon:recPlayer(ununmarshalledRec))
        addonData.summon:showSummons()
      end

      --- clickers
    elseif cmd == "c" then
      local locks, clickers = strsplit("+", subcmd)
      db("gossip", "<< clickers <<", sender, locks, clickers)

      self:setClicks(locks, clickers)

      --- chat this
    elseif cmd == "ct" then
      if sender == self.netList[1] then -- at least protect from people other than net lead abusing this
        local msgtype, to = strsplit(" ", subcmd)
        if not msgtype or msgtype == "" then
          msgtype = to
        end
        db("gossip", "<< chat this <<", sender, msgtype, to)
        self:chatThis(msgtype, to)
      end

      --- initialize
    elseif cmd == "i" then
      -- initialize requestor, if deputy init leader when they /reload
      if self:isLeader() or (self.netList[1] == sender and self.netList[2] == self.me) then
        db("gossip", "<< initialize request <<")
        if addonData.summon.numwaiting then
          local data = addonData.util:marshalWaitingTable()
          local dl = addonData.util:tableToMultiLine(self.atDest, "\n")
          db("gossip", ">> initialize reply >>")
          -- first set their destination
          self:destination(addonData.summon.zone, addonData.summon.location, nil, sender)
          -- then send the dest list
          db("gossip", ">> destination list >> WHISPER", sender, dl)
          self:SendCommMessage(self.channel, "dl " .. dl, "WHISPER", sender, "BULK")
          -- next waiting list
          db("gossip", ">> waiting list >> WHISPER", sender, data)
          self:SendCommMessage(self.channel, "l " .. data, "WHISPER", sender, "BULK")
          local toggle = "true"
          if addonData.summon.infoSend == false then
            toggle = "false"
          end
          db("gossip", ">> nag >> WHISPER", sender, toggle)
          self:SendCommMessage(self.channel, "n " .. toggle, "WHISPER", sender)
        end
      end

      --- alt list
    elseif cmd == "alt" then
      db("gossip", "<< alt list <<", sender)
      local player, altmarshalled = strsplit("+", subcmd)
      local alts = addonData.summon:unmarshallAlts(altmarshalled)
      db("gossip", player, alts)

      if self:isLeader() then
        self:alts(player, alts)
      else
        local rec = addonData.summon:findWaitingPlayer(player)
        if rec then
          addonData.summon:recMergeAlts(rec, alts)
        end
      end

      --- alt whispered
    elseif cmd == "wsp" then
      db("gossip", "<< alt whispered <<", sender)
      local player, alt = strsplit("+", subcmd)
      local rec = addonData.summon:findWaitingPlayer(player)
      if rec then
        addonData.summon:recAltWhispered(rec, alt)
      end
      if self:isLeader() then
        self:altWhispered(player, alt)
      end

      --- leave netgroup (turned off comms or had a bad version)
    elseif cmd == "retire" then
      if sender == self.me then
        db("gossip", "ignoring my own retire from before reload")
      end
      if self.inInit then
        return -- group messages get saved up on reload...
      end
      db("gossip", "<< retire <<", sender)
      self:raiderLeft(sender)

      --- destination list
    elseif cmd == "dl" then
      if not senderIsLeader() then return end

      db("gossip", "<< at destination list <<")
      self.atDest = addonData.util:multiLineToMap(subcmd, "\n")
      self.atDestCount = 0
      self.locksCount = 0
      for i,_ in pairs(self.atDest) do
        self:updateCounts(true, i)
      end

      db("gossip", "at destination count:", self.atDestCount)

    elseif cmd == "l" then
      if not senderIsLeader() then return end

      db("gossip", "<< waiting list <<", subcmd)
      addonData.util:unmarshalWaitingTable(subcmd)
      self:replayMessageLog(self.replayLog)

      --- nag toggle
    elseif cmd == "n" then
      db("gossip", "<< nag <<", subcmd)
      addonData.summon:setRaidNags(subcmd == "true")

      --- destination change
    elseif cmd == "d" then
      local destination = string.gsub(subcmd, "_", " ")
      local zone, location = strsplit("+", destination)
      db("gossip", "<< destination <<", zone, location)

      if zone == nil or location == nil then
        zone = ""
        location = ""
      end
      if self:isLeader() then
        self:destination(zone, location)
      else
        addonData.summon:setDestination(zone, location)
        self:wipeCounts()
      end

      --- at destination
    elseif cmd == "atD" then
      local player, at = strsplit("+", subcmd)
      at = at == "true"
      db("gossip", "<< at destination <<", player, at)

      if self:isLeader() then
        self:atDestination(at, player)
      else
        if (self.atDest[player] == nil and at) or (self.atDest[player] and not at) then
          self.atDest[player] = at or nil
          self:updateCounts(at, player)
        end
        db("gossip", "at destination count:", self.atDestCount)
      end

      --- status change
    elseif cmd == "s" then
      local player, status = strsplit("+", subcmd)
      db("gossip", "<< status <<", sender, player, status)
      if self:isLeader() then
        self:status(player, status)
      else
        addonData.summon:status(player, status)
        if status == "offline" then
          self.atDest[player] = nil
          self:updateCounts(false, player)
        end
      end

      --- netgroup list
    elseif cmd == "netlist" then
      db("gossip", "<< netlist <<", sender)
      if sender == self.me then -- on replay
        db("gossip", "ignored netlist from myself")
        return
      end
      self.netList = addonData.util:multiLineToTable(subcmd, "\n")
      if self.inInit then
        -- 2. if within 5 seconds a network list is received, request initialize from leader
        self.inInit = false
        if self.netlistTimer and not self.netlistTimer:IsCancelled() then
          self.netlistTimer:Cancel()
        end
        self:initialize()
      end

      --- denied - on old version
    elseif cmd == "v" then
      db("gossip", "<< Bad Version <<")
      cprint(L["version"])
      self:netOn(false)
      self.versionBad = true

      --- request for netgroup list
    elseif cmd == "netreq" then
      if sender == self.me then -- on replay
        db("gossip", "ignored netreq from myself")
        return
      end
      db("gossip", "<< netreq <<", sender)
      -- 4. if while waiting for network list, you receive a request for the network list,
      -- whisper election and add the requester to the voting list,
      local votes, version = strsplit("+", subcmd)

      -- deny old protocol versions
      if version == nil or tonumber(version) < tonumber(self.version) then
        db("gossip", ">> Bad Version >>")
        db("gossip", "My version:", self.version, "sender", sender, "version:", version)
        self:SendCommMessage(self.channel, "v " .. self.version , "WHISPER", sender)
        return
      elseif version ~= nil and tonumber(version) > tonumber(self.version) then
        -- including this one
        db("gossip", "My version:", self.version, "sender", sender, "version:", version)
        cprint(L["version"])
        self:netOn(false)
        self.versionBad = true
        return
      end

      if self.inInit then
        if not addonData.util:isInTable(self.votingBooth, votes) then
          table.insert(self.votingBooth, votes)
        end
        db("gossip", ">> election >>", sender)
        self:SendCommMessage(self.channel, "e " .. self.votes, "WHISPER", sender, "ALERT")
      else
        -- 6. upon receipt of a request for network list, add requester to list
        local inTable = addonData.util:isInTable(self.netList, sender)
        if not inTable then
          table.insert(self.netList, sender)
        end
        -- send netlist, make sure to recover leader when they /reload or something
        if self:isLeader() or (inTable and self.netList[1] == sender and self.netList[2] == self.me) then
          -- 6a. if network leader, whisper network list
          self:netListSend(sender)
        end
      end

      --- notification of election, sender in init
    elseif cmd == "e" then
      db("gossip", "<< election <<")
      -- 5. if you ask for a network list and receive "election", add GUID to voting
      if self.inInit then
        if not addonData.util:isInTable(self.votingBooth, subcmd) then
          table.insert(self.votingBooth, subcmd)
        end
      else
        db("gossip", "election in progress reported, but I am already out of the init phase, ignoring")
      end

      --- election over, create net list
    elseif cmd == "edone" then
      if self.inInit then
        db("gossip", "<< election over <<", sender)
        self.inInit = false
        if self.netlistTimer and not self.netlistTimer:IsCancelled() then
          self.netlistTimer:Cancel()
        end
        self:postInit()
      end

      --- SteaSummon version broadcast
    elseif cmd=="version" then
      if sender == self.me then -- on replay
        db("gossip", "ignored version request from myself")
        return
      end
      db("gossip", "<< version <<", sender)
      local reported_version = tonumber(subcmd)
      db("gossip", "my version:", self.SSversion, sender, "version:", reported_version)
      if reported_version < self.SSversion then
        self:SteaSummonVersion(sender)
      end
      if not self.SSversion_notified and reported_version > self.SSversion then
        db("gossip", "I have an old version <<")
        self.SSversion_notified = true
        cprint(L["There is a newer version available."])
      end
    else
      db("gossip", "Unknown protocol command received:", cmd)
    end
  end
}

LibStub("AceComm-3.0"):Embed(gossip)
addonData.gossip = gossip
