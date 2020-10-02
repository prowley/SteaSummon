-- comms for the addon network
-- CHAT_MSG_ADDON

local _, addonData = ...

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


-- leader/network management
----------------------------
-- 1. On first raidJoin, request network list
-- 2. if within 5 seconds a network list is received, request initialize from leader
-- 3. if not received, you are the first one on the list and network leader
-- 4. if while waiting for network list, you receive a request for the network list,
    -- whisper election and add the requester to a temp list,
-- 4a. the temp list is destroyed if a network list is received, or used as network list if become leader
-- 4b. upon becoming leader, whisper network list to the temp list
-- 5. if you ask for a network list and receive "election", wait 5 seconds for the network list to arrive
-- 6. upon receipt of a request for network list, add requester to list
-- 6a. if network leader, whisper network list
-- 8. when someone goes offline or leaves raid that is in the list, remove their name, you may become leader
-- 9. if comms setting turned on, and in group, goto 1
--10. if comms setting turned off, and in group, send withdrawing

local gossip = {
  channel = "SteaSummon",
  netlistTimer = nil,
  tmpOps = {},
  netList = {},
  tmpList = {},
  inInit = true,
  atDest = {},
  atDestCount = 0,
  atDestTimer = nil,
  me = nil,

  ---------------------------------
  init = function(self)
    addonData.debug:registerCategory("gossip.event")
    -- register addon comms channel
    local commsgood = self:RegisterComm(self.channel, "callback")
    db("addon channel registered: ", commsgood)
    self.netlistTimer = addonData.monitor:create(5, self.netListTimeout, false)
    self.atDestTimer = addonData.monitor:create(2, self.atDestAction, false)
    self.me, _ = UnitName("player")
  end,

  ---------------------------------
  netOn = function(self, on)
    if on == nil or on then
      if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        self:raidJoined()
      end
    else
      if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        db("gossip", ">> retire >> Broadcast")
        self:SendCommMessage(self.channel, "retire", "RAID")
      end
      self:raidLeft()
    end
  end,

  ---------------------------------
  netListTimeout = function(self)
    db("gossip", "TIMED OUT waiting for netlist")
    self = addonData.gossip
    if self.inInit then
      self.inInit = false
      -- 4a. the temp list is destroyed if a network list is received, or used as network list if become leader
      self.netList = self.tmpList
      -- 4b. upon becoming leader, whisper network list to the temp list
      for i,v in pairs(self.netList) do
        if i ~= 1 then -- skip ourselves
          self:netListSend(v)
        end
      end
    end
  end,

  ---------------------------------
  netListSend = function(self, player)
    if not addonData.settings:useUpdates() then
      return
    end

    local msg = "netList " .. addonData.util:tableToMultiLine(self.netList)
    db("gossip", ">> netlist send >> whisper", player)
    self:SendCommMessage(self.channel, msg, "WHISPER", player)
  end,

  ---------------------------------
  raidJoined = function(self)
    if not addonData.settings:useUpdates() then
      return
    end

    db("gossip", "group joined")
    if self.inInit then
      -- 1. On first raidJoin, request network list
      db("gossip", ">> netreq >> Broadcast")
      self:SendCommMessage(self.channel, "netreq", "RAID")
      -- 3. if not received, you are the first one on the list and network leader
      table.insert(self.tmpList, 1, self.me)
      self.netlistTimer:Play()
    end
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
      table.remove(self,netList, v)
    end
  end,

  ---------------------------------
  raiderLeft = function(self, player)
    if not addonData.settings:useUpdates() then
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
    for i,v in pairs(self.tmpList) do
      if v == player then
        db("gossip", player, "left net group")
        table.remove(self.tmpList, i)
        break
      end
    end
    self.atDest[player] = nil
  end,

  ---------------------------------
  raidLeft = function(self)
    db("gossip", "You left net group")
    self.inInit = true
    self.netlistTimer:Stop()
    wipe(self.netList)
    self.tmpList = {}
    wipe(self.atDest)
  end,

  ---------------------------------
  isLeader = function(self)
    if not addonData.settings:useUpdates() then
      return true
    end

    return self.netList[1] == self.me
  end,

  ---------------------------------
  status = function(self, player, status)
    self:offlineCheck()

    if self:isLeader() then
      db("gossip", ">> status >> RAID", player, status)
      local idx = addonData.summon:findWaitingPlayerIdx(player)
      if idx then
        if addonData.summon:recStatus(addonData.summon.waiting[idx]) ~= status then
          addonData.summon:recStatus(addonData.summon.waiting[idx], status)
          if not addonData.settings:useUpdates() then
            return
          end
          self:SendCommMessage(self.channel, "s " .. tostring(idx) .. "+" .. status, "RAID")
        end
      end
    else
      db("gossip", ">> status >> WHISPER", player, status)
      self:SendCommMessage(self.channel, "s " .. player .. "+" .. status, "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  arrived = function(self, player)
    self:offlineCheck()

    if self:isLeader() then
      db("gossip", ">> arrived >> RAID", player)
      if addonData.summon:findWaitingPlayerIdx(player) then
        addonData.summon:arrived(player)
        if not addonData.settings:useUpdates() then
          return
        end
        self:SendCommMessage(self.channel, "a " .. player, "RAID")
      end
    else
      db("gossip", ">> arrived >> WHISPER", player)
      self:SendCommMessage(self.channel, "a " .. player, "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  add = function(self, player, isWhisper)
    self:offlineCheck()

    if self:isLeader() then
      db("gossip", ">> add >> RAID", player)
      local index = addonData.summon:findWaitingPlayerIdx(player)
      if not index then
        local idx = addonData.summon:addWaiting(player)
        if not addonData.settings:useUpdates() then
          return
        end
        local rec = addonData.summon:recMarshal(addonData.summon.waiting[idx])
        self:SendCommMessage(self.channel, "adrec " .. tostring(idx) .. " " .. rec, "RAID")
      else
        addonData.summon:addWaiting(player, true)
        self:status(player, "requested")
      end
    else
      if isWhisper then
        db("gossip", ">> add >> WHISPER", player)
        self:SendCommMessage(self.channel, "ad " .. player, "WHISPER", self.netList[1])
      end
    end
  end,

  ---------------------------------
  destination = function(self, zone, location)
    self:offlineCheck()

    local destination = string.gsub(zone .. "+" .. location, " ", "_")

    if self:isLeader() then
      db("gossip", ">> destination >> RAID", zone, location)
      addonData.summon:setDestination(zone,location)
      if not addonData.settings:useUpdates() then
        return
      end
      self:SendCommMessage(self.channel, "d " .. destination, "RAID")
    else
      db("gossip", ">> destination >> WHISPER", zone, location)
      self:SendCommMessage(self.channel, "d " .. destination, "WHISPER", self.netList[1])
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
      if (self.atDest[name] == nil and at) or (self.atDest[name] and not at) then
        self.atDest[name] = at or nil
        if at then
          self.atDestCount = self.atDestCount + 1
        else
          self.atDestCount = self.atDestCount - 1
        end

        if not addonData.settings:useUpdates() then
          if self.atDestCount == 0 then
            self:destination("", "") -- you have moved on
          end
          return
        end

        db("gossip", ">> atDestination >> RAID", at)
        self:SendCommMessage(self.channel, "atD " .. self.netList[1] .. "+" .. tostring(at), "RAID")
        if settingSelf then
          if self.atDestCount == 0 then
            if self.atDestTimer:IsPlaying() then
              self.atDestTimer:Stop() -- make sure we wait full duration on hitting zero
            end
            self.atDestTimer:Play()
          end
        end
      end
    else
      local me, _ = UnitName("player")
      self:SendCommMessage(self.channel, "atD " .. me .. "+" .. tostring(at), "WHISPER", self.netList[1])
    end
  end,

  ---------------------------------
  atDestAction = function(self)
    db("gossip", "checking for zero destination")
    self = addonData.gossip
    if self.atDestCount == 0 and self:isLeader() then
      self:destination("", "") -- the raid has moved on
    end
  end,

  ---------------------------------
  initialize = function(self)
    if not addonData.settings:useUpdates() then
      return
    end

    self:offlineCheck()
    db("gossip", ">> initialize >> WHISPER", self.netList[1])
    self:SendCommMessage(self.channel, "i", "WHISPER", self.netList[1])
  end,

  ---------------------------------
  callback = function(self, prefix, msg, dist, sender, ... )
    if prefix ~= self.channel then
      return
    end
    db("gossip.event", "prefix:", prefix, "msg:", msg, "dist:", dist, "sender:", sender, ...)
    if not addonData.settings:useUpdates() then
      return
    else
      if sender ~= self.me then
        addonData.gossip:receive(msg, dist, sender, ... )
      end
    end
  end,

  ---------------------------------
  receive = function(self, msg, _, sender, ... )
    local cmd, subcmd strsplit(" ", msg)

    if cmd == nil then
      cmd = msg -- blizzard, really? Every strsplit function ever passes back the whole string if no delimiter is found...
    end

    db ("gossip.event", "command", cmd, "from", sender)

    if cmd == "s" then
      p, s = strsplit("-", subcmd)
      db("gossip", "<< status <<", p, s)
      addonData.summon:status(p, s)

    elseif cmd == "a" then
      db("gossip", "<< arrived <<", subcmd)

      if self:isLeader() then
        self:arrived()
      else
        addonData.summon:arrived(subcmd)
      end

    elseif cmd == "ad" then
      db("gossip", "<< add <<", subcmd)
      if self:isLeader() then
        self:add(subcmd)
      end

    elseif cmd == "adrec" then
      local i, rec = strsplit(" ", subcmd)
      db("gossip", "<< add record <<", rec)
      table.insert(addonData.summon.waiting, tonumber(i), addonData.summon:recUnMarshal(rec))
      addonData.summon:showSummons()

    elseif cmd == "i" then
      if self:isLeader() then
        db("gossip", "<< initialize request <<")
        if addonData.summon.numwaiting then
          local data = addonData.util:marshalWaitingTable()
          local dl = addonData.util:tableToMultiLine(self.atDest)
          db("gossip", ">> initialize reply >>", data)
          -- first send the dest list
          self:SendCommMessage(self.channel, "dl " .. dl, "WHISPER", sender)
          -- next waiting list
          self:SendCommMessage(self.channel, "l " .. data, "WHISPER", sender)
          -- then set their destination
          self.destination(addonData.summon.zone, addonData.summon.location)
        end
      end

    elseif cmd == "retire" then
      local idx

      for i, v in pairs(self.netList) do
        if v == sender then
          idx = i
        end
      end

      if idx then
        table.remove(self.netList, idx)
      end

    elseif cmd == "dl" then
      db("gossip", "<< at destination list <<")
      self.atDest = addonData.util:multiLineToTable(subcmd)

    elseif cmd == "l" then
      db("gossip", "<< waiting list <<", subcmd)
      if sender == self.netList[1] then
        addonData.util:unmarshalWaitingTable(subcmd)
      end

    elseif cmd == "d" then
      local destination = string.gsub(subcmd, "_", " ")
      local zone, location = strsplit("+", destination)
      db("gossip", "<< destination <<", zone, location)
      addonData.summon:setDestination(zone, location)
      if self:isLeader() then
        self:destination(zone, location)
      end

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

      if self.atDestCount == 0 then
        -- on setting destination we will get a storm of atD reports (up to 39), and a good deal of those might be
        -- "not at destination" - so when we reach zero at destination we should wait a bit to get final tally
        -- then decide if we need to null the destination
        if self.atDestTimer:IsPlaying() then
          self.atDestTimer:Stop() -- make sure we wait full duration on hitting zero
        end
        self.atDestTimer:Play()
      end

      if self:isLeader() then
        -- carry on as normal otherwise, it might hit zero later, but it will be dealt with if its finally zero
        -- by whoever is the leader at that time
        self:atDestination(at, player)
      end

    elseif cmd == "s" then
      local player, status = strsplit("+", subcmd)
      db("gossip", "<< status <<", sender, player, status)
      if self:isLeader() then
        self:status(player, status)
      else
        addonData.summon:recStatus(self.waiting[player], status)
      end

    elseif cmd == "netlist" then
      db("gossip", "<< netlist <<")
      self.netList = addonData.util.multiLineToTable(subcmd)
      if self.inInit then
        -- 2. if within 5 seconds a network list is received, request initialize from leader
        self.inInit = false
        self.netlistTimer:Stop()
        self:initialize()
      end

    elseif cmd == "netreq" then
      db("gossip", "<< netreq <<")
      -- 4. if while waiting for network list, you receive a request for the network list,
      -- whisper election and add the requester to a temp list,
      if self.inInit then
        table.insert(self.tmpList, sender)
        self:SendCommMessage(self.channel, "e", "WHISPER", sender)
      else
        -- 6. upon receipt of a request for network list, add requester to list
        table.insert(self.netList, sender)
        if self:isLeader() then
          -- 6a. if network leader, whisper network list
          self:netListSend(sender)
        end
      end

    elseif cmd == "e" then
      db("gossip", "<< election <<")
      -- 5. if you ask for a network list and receive "election", wait 5 seconds for the network list to arrive
      if self.inInit then
        self.netlistTimer:Stop()
        self.netlistTimer:Play()
      end
    end
  end
}

LibStub("AceComm-3.0"):Embed(gossip)
addonData.gossip = gossip