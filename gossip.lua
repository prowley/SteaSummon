-- comms for the addon network
-- CHAT_MSG_ADDON

local addonName, addonData = ...

-- protocol
-----------
-- s summon
-- a arrived
-- i initialize me
-- l waiting list
-- d destination

-- TODO: addon protocol
-- e election

local gossip = {
  summoned = function(self, player)
    if not addonData.settings:useUpdates() then
      return
    end

    if (addonData.util:playerCanSummon()) then
      C_ChatInfo.SendAddonMessage(addonData.channel, "s " .. player, "RAID")
    end
  end,

  arrived = function(self, player)
    if not addonData.settings:useUpdates() then
      return
    end

    C_ChatInfo.SendAddonMessage(addonData.channel, "a " .. player, "RAID")
  end,

  destination = function(self, zone, location)
    if not addonData.settings:useUpdates() then
      return
    end
    local destination = location .. "+" .. zone
    location = string.gsub(location, " ", "_")
    C_ChatInfo.SendAddonMessage(addonData.channel, "d " .. destination, "RAID")
  end,

  initialize = function(self)
    if not addonData.settings:useUpdates() then
      return
    end

    C_ChatInfo.SendAddonMessage(addonData.channel, "i me", "RAID")
  end,

  callback = function(self, event, prefix, msg, ... )
    if not addonData.settings:useUpdates() then
      return
    end

    if prefix ~= addonData.channel then
      return
    end
    local cmd, player strsplit(" ", msg)
    if cmd == "s" then
      addonData.summon:summoned(player)
    elseif cmd == "a" then
      addonData.summon:arrived(player)
    elseif cmd == "i" then
      if addonData.summon.numwaiting then
        local data = addonData.util:marshalWaitingTable()
        C_ChatInfo.SendAddonMessage(addonData.channel, "l " .. data, "RAID")
      end
    elseif cmd == "l" then
      addonData.util:unmarshalWaitingTable(player)
    elseif cmd == "d" then
      local destination = string.gsub(destination, "_", " ")
      local location, zone = strsplit(",", destination)
      addonData.summon:setDestination(zone, location)
    end
  end
}

addonData.gossip = gossip