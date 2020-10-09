-- comms for the addon network
-- CHAT_MSG_ADDON

local addonName, addonData = ...
local L = LibStub("AceLocale-3.0"):GetLocale("SteaSummon")

-- protocol
-----------
-- a arrived
-- ad add player
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

local DEFAULT_NETLIST_TIME = 5


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
      if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        db("gossip", ">> retire >>", self:groupText())
        self:SendCommMessage(self.channel, "retire", self:groupText())
      end
      self:raidLeft()
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
    for _,v in pairs(self.votingBooth) do
      local _, _, _, _, _, name = GetPlayerInfoByGUID(v)
      db("gossip", "netlist:", name)
      if not addonData.util:isInTable(self.netList, name) then
        table.insert(self.netList, name)
      end
    end

    if not self:isLeader() then
      self:initialize()
    end
    self:replayMessageLog(self.replayLog)
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

    local msg = "netlist " .. addonData.util:tableToMultiLine(self.netList)
    db("gossip", ">> netlist send >> WHISPER", player)
    self:SendCommMessage(self.channel, msg, "WHISPER", player)
  end,

  ---------------------------------
  raidJoined = function(self)
    if self:noComms() then
      return
    end

    db("gossip", "group joined")
    if self.inInit and not self.versionBad then
      -- 1. On first raidJoin, request network list
      db("gossip", ">> netreq >>", self:groupText())
      self:SendCommMessage(self.channel, "netreq ".. self.votes.. "+"
          .. self.version, self:groupText(), "ALERT")
      -- 3. if not received, you are the first one on the list and network leader
      table.insert(self.votingBooth, 1, self.votes)
      self.netlistTimer = C_Timer.NewTimer(DEFAULT_NETLIST_TIME, self.netListTimeout)
    end
    self:SteaSummonVersion()
  end,

  ---------------------------------
  offlineCheck = function(self)
    local killList = {}
    for i,v in pairs(self.netList) do
      if not UnitIsConnected(v) then
        table.insert(killList, 1, i)
      end
    end

    for _, v in pairs(killList) do
      table.remove(self.netList, v)
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

    self.atDest[player] = nil
  end,

  ---------------------------------
  raidLeft = function(self)
    db("gossip", "You left net group")
    if self.netlistTimer and not self.netlistTimer:IsCancelled() then
      self.netlistTimer:Cancel()
    end
    addonData.summon:listClear()
    self.recvElections = 0
    self.inInit = true
    wipe(self.netList)
    self.votingBooth = {}
    wipe(self.atDest)
    self.atDestCount = 0
    wipe(self.replayLog)
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
  status = function(self, player, status)
    self:offlineCheck()

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
  arrived = function(self, player)
    self:offlineCheck()

    if self:isLeader() then
      if addonData.summon:findWaitingPlayerIdx(player) then
        addonData.summon:arrived(player)
        if self:noComms() then
          return
        end
        db("gossip", ">> arrived >>", self:groupText(), player)
        self:SendCommMessage(self.channel, "a " .. player, self:groupText())
      end
    else
      if self:noComms() then
        return
      end
      db("gossip", ">> arrived >> WHISPER", player)
      self:SendCommMessage(self.channel, "a " .. player, "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  add = function(self, player, isWhisper)
    self:offlineCheck()

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
      else
        addonData.summon:addWaiting(player, true)
        self:status(player, "requested")
      end
    else
      if self:noComms() then
        return
      end
      if isWhisper then
        db("gossip", ">> add >> WHISPER", player)
        self:SendCommMessage(self.channel, "ad " .. player, "WHISPER", self.netList[1])
      end
    end
  end,

  ---------------------------------
  destination = function(self, zone, location, noSet, player)
    self:offlineCheck()

    local destination = string.gsub(zone .. "+" .. location, " ", "_")

    if not player and self:isLeader() then
      db("gossip", ">> destination >>", self:groupText(), destination)
      if not noSet then
        addonData.summon:setDestination(zone,location)
      end
      if self:noComms() then
        return
      end

      if zone == "" then
        wipe(self.atDest)
        self.atDestCount = 0
      end
      self:SendCommMessage(self.channel, "d " .. destination, self:groupText())
    else
      if self:noComms() then
        return
      end
      if not player then
        player = self.netList[1]
      end
      db("gossip", ">> destination >> WHISPER", player, destination)
      self:SendCommMessage(self.channel, "d " .. destination, "WHISPER", player)
    end
  end,

  ---------------------------------
  atDestination = function(self, at, name)
    if self:isLeader() then
      local settingSelf = false
      if not name then
        name = self.me
        settingSelf = true
      end
      if (settingSelf and self.atDest[name] == nil and at) or (self.atDest[name] and not at) then
        self.atDest[name] = at or nil

        if settingSelf then
          if at then
            self.atDestCount = self.atDestCount + 1
          else
            self.atDestCount = self.atDestCount - 1
          end
        end
      end

      db("gossip", "at destination count:", self.atDestCount)

      if self:noComms() then
        if self.atDestCount == 0 then
          self:destination("", "") -- you have moved on
        end
        return
      end

      if self.atDestCount == 0 then
        self:destination("", "") -- the raid has moved on
      else
        db("gossip", ">> atDestination >>", self:groupText(), name, at)
        self:SendCommMessage(self.channel, "atD " .. self.netList[1] .. "+" .. tostring(at), self:groupText())
      end

    else
      if self:noComms() then
        return
      end
      db("gossip", ">> atDestination >> WHISPER", self.netList[1], at)
      self:SendCommMessage(self.channel, "atD " .. self.me .. "+" .. tostring(at), "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  atDestAction = function(self)
    db("gossip", "checking for zero destination")
    self = addonData.gossip
    self.atDestTimer = nil
    if self.atDestCount == 0 and self:isLeader() then
      self:destination("", "") -- the raid has moved on
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
      if sender ~= self.me then
        addonData.gossip:receive(msg, dist, sender, ... )
      end
    end
  end,

  ---------------------------------
  receive = function(self, msg, _, sender, ... )
    local cmd, subcmd = strsplit(" ", msg)
    local okForInit = {
      ["netlist"] = 1,
      ["e"] = 1,
      ["edone"] = 1,
      ["version"] = 1,
      ["netreq"] = 1,
      ["retire"] = 1,
      ["v"] = 1}

    db ("gossip.event", "message", cmd, "from", sender, "payload:", subcmd)

    -- While we are in init things don't stop happening, but we are not in a position
    -- to properly respond to those things yet, so we store messages other than those
    -- pertinent to init and we replay those later once we are properly initialized
    -- e.g. we might end up being leader and have to initialize others, or a summon
    -- request could come in while we don't know who is leader, or instructions to
    -- change the status for someone in a waiting list we don't have yet
    if self.inInit and not okForInit[cmd] then
      table.insert(self.replayLog, {msg, sender})
      return
    end

    --- arrive
    if cmd == "a" then
      db("gossip", "<< arrived <<", subcmd)

      if self:isLeader() then
        self:arrived(subcmd)
      else
        addonData.summon:arrived(subcmd)
      end

      --- add player
    elseif cmd == "ad" then
      db("gossip", "<< add <<", subcmd)
      if self:isLeader() then
        self:add(subcmd)
      end

      --- add record
    elseif cmd == "adrec" then
      local i, rec = strsplit("_", subcmd)
      db("gossip", "<< add record <<", rec)
      local ununmarshalledRec = addonData.summon:recUnMarshal(rec)
      if not addonData.summon:findWaitingPlayer(addonData.summon:recPlayer(ununmarshalledRec)) then
        addonData.summon:recAdd(ununmarshalledRec, tonumber(i))
        addonData.summon:showSummons()
      end

      --- initialize
    elseif cmd == "i" then
      -- initialize requestor, if deputy init leader when they /reload
      if self:isLeader() or (self.netList[1] == sender and self.netList[2] == self.me) then
        db("gossip", "<< initialize request <<")
        if addonData.summon.numwaiting then
          local data = addonData.util:marshalWaitingTable()
          local dl = addonData.util:tableToMultiLine(self.atDest)
          db("gossip", ">> initialize reply >>", data)
          -- first send the dest list
          self:SendCommMessage(self.channel, "dl " .. dl, "WHISPER", sender, "BULK")
          -- then set their destination
          self:destination(addonData.summon.zone, addonData.summon.location, nil, sender)
          -- next waiting list
          self:SendCommMessage(self.channel, "l " .. data, "WHISPER", sender, "BULK")
        end
      end

      --- leave netgroup (turned off comms or had a bad version)
    elseif cmd == "retire" then
      db("gossip", "<< retire <<", sender)
      self:raiderLeft(sender)

      --- destination list
    elseif cmd == "dl" then
      db("gossip", "<< at destination list <<")
      self.atDest = addonData.util:multiLineToMap(subcmd)
      self.atDestCount = 0
      for _,_ in pairs(self.atDest) do
        self.atDestCount = self.atDestCount + 1
      end

    elseif cmd == "l" then
      db("gossip", "<< waiting list <<", subcmd)
      addonData.util:unmarshalWaitingTable(subcmd)
      self:replayMessageLog(self.replayLog)

      --- destination change
    elseif cmd == "d" then
      local destination = string.gsub(subcmd, "_", " ")
      local zone, location = strsplit("+", destination)
      db("gossip", "<< destination <<", zone, location)
      if zone == "" then
        self.atDestCount = 0
        wipe(self.atDest)
      end
      addonData.summon:setDestination(zone, location)
      if self:isLeader() then
        self:destination(zone, location, true)
      end

      --- at destination
    elseif cmd == "atD" then
      local player, at = strsplit("+", subcmd)
      at = at == "true"
      db("gossip", "<< at destination <<", player, at)

      self.atDest[player] = at or nil

      if at then
        self.atDestCount = self.atDestCount + 1
      else
        self.atDestCount = self.atDestCount - 1
      end

      if self:isLeader() then
        -- carry on as normal otherwise, it might hit zero later, but it will be dealt with if its finally zero
        -- by whoever is the leader at that time
        self:atDestination(at, player)
      end

      --- status change
    elseif cmd == "s" then
      local player, status = strsplit("+", subcmd)
      db("gossip", "<< status <<", sender, player, status)
      if self:isLeader() then
        self:status(player, status)
      else
        addonData.summon:status(player, status)
      end

      --- netgroup list
    elseif cmd == "netlist" then
      db("gossip", "<< netlist <<")
      self.netList = addonData.util:multiLineToTable(subcmd)
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
      db("gossip", "<< netreq <<")
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

      --- SteaSummon version broadcast GUILD
    elseif cmd=="version" then
      db("gossip", "<< version <<", sender)
      local reported_version = tonumber(subcmd)
      if reported_version < self.SSversion then
        self:SteaSummonVersion(sender)
      end
      if not self.SSversion_notified and reported_version > self.SSversion then
        db("gossip", "I have an old version <<")
        self.SSversion_notified = true
        cprint(L["There is a newer version available."])
      end
    end
  end
}

LibStub("AceComm-3.0"):Embed(gossip)
addonData.gossip = gossip