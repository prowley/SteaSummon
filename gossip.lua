-- comms for the addon network
-- CHAT_MSG_ADDON

local addonName, addonData = ...

-- protocol
-----------
-- a arrived
-- d destination
-- TODO: e election (reduce network traffic by having leader do the thing, right now everyone replies to i - packet storm)
-- i initialize me
-- l waiting list
-- s status



local gossip = {
  init = function(self)
    addonData.debug:registerCategory("gossip.event")
  end,

  callback = function(self, event, ...)
    db("gossip.event", event, ...)
    if event == "PARTY_LEADER_CHANGED" then
      gossip:initialize()
    end
  end,

  status = function(self, player, status)
    if not addonData.settings:useUpdates() then
      return
    end

    if (addonData.util:playerCanSummon()) then
      db("gossip", ">> status >>", player, status)
      C_ChatInfo.SendAddonMessage(addonData.channel, "s " .. player .. "-" .. status, "RAID")
    end
  end,

  arrived = function(self, player)
    if not addonData.settings:useUpdates() then
      return
    end

    db("gossip", ">> arrived >>", player)
    C_ChatInfo.SendAddonMessage(addonData.channel, "a " .. player, "RAID")
  end,

  destination = function(self, zone, location)
    if not addonData.settings:useUpdates() then
      return
    end

    db("gossip", ">> destination >>", zone, location)
    local destination = location .. "+" .. zone
    location = string.gsub(location, " ", "_")
    C_ChatInfo.SendAddonMessage(addonData.channel, "d " .. destination, "RAID")
  end,

  initialize = function(self)
    if not addonData.settings:useUpdates() then
      return
    end

    db("gossip", ">> initialize >>")
    C_ChatInfo.SendAddonMessage(addonData.channel, "i me", "RAID")
  end,

  callback = function(self, event, prefix, msg, ... )
    if not addonData.settings:useUpdates() then
      return
    end

    if prefix ~= addonData.channel then
      return
    end
    local cmd, subcmd strsplit(" ", msg)
    if cmd == "s" then
      p, s = strsplit("-", subcmd)
      db("gossip", "<< status <<", p, s)
      addonData.summon:status(p, s)
    elseif cmd == "a" then
      db("gossip", "<< arrived <<", subcmd)
      addonData.summon:arrived(subcmd)
    elseif cmd == "i" then
      db("gossip", "<< initialize request <<")
      if addonData.summon.numwaiting then
        local data = addonData.util:marshalWaitingTable()
        db("gossip", ">> initialize reply >>", data)
        C_ChatInfo.SendAddonMessage(addonData.channel, "l " .. data, "RAID")
      end
    elseif cmd == "l" then
      db("gossip", "<< initialize response <<", subcmd)
      addonData.util:unmarshalWaitingTable(subcmd)
    elseif cmd == "d" then
      local destination = string.gsub(subcmd, "_", " ")
      local location, zone = strsplit(",", destination)
      db("gossip", "<< destination <<", location, zone)
      addonData.summon:setDestination(zone, location)
    end
  end
}

addonData.gossip = gossip