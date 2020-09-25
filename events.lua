-- event setup

local addonName, addonData = ...
local call = {}

function start()
  db("start")

  -- build callback table
  call["ADDON_LOADED"] = loaded
  call["PLAYER_ENTERING_WORLD"] = playerEnter
  call["CHAT_MSG_PARTY"] = addonData.chat.callback
  call["CHAT_MSG_PARTY_LEADER"] = addonData.chat.callback
  call["CHAT_MSG_RAID"] = addonData.chat.callback
  call["CHAT_MSG_RAID_LEADER"] = addonData.chat.callback
  call["CHAT_MSG_ADDON"] = addonData.gossip.callback
  call["CHAT_MSG_SAY"] = addonData.chat.callback
  call["PARTY_LEADER_CHANGED"] = addonData.gossip.callback
  call["GROUP_ROSTER_UPDATE"] = addonData.raid.callback
  call["RAID_ROSTER_UPDATE"] = addonData.raid.callback
  call["PLAYER_REGEN_DISABLED"] = addonData.summon.callback
  call["UNIT_SPELLCAST_START"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_STOP"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_FAILED"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_INTERRUPTED"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_FAILED_QUIET"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_DELAYED"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_CHANNEL_START"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_CHANNEL_UPDATE"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_CHANNEL_STOP"] = addonData.summon.castWatch

   -- set up the load event
  frame = CreateFrame("Frame")
  frame:RegisterEvent("ADDON_LOADED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", callback)
end

function callback(self, event, ...)
  if call[event] ~= nil then
    call[event](self, event, ...)
  end
end

function playerEnter(event, ...)
  db("event", "player entering world")

  -- register events
  for k,v in pairs(call) do
    if k ~= "ADDON_LOADED" then
      db("event","registering event", k)
      frame:RegisterEvent(k)
    end
  end
end

function loaded(self, event, ...)
  local name = ...

  -- if it this addon
  if (name == addonName) then
    -- this the first point that settings are loaded, and therefore the "debug" flag
    -- so db won't log anything before now, also not safe to call category debug before now
    addonData.debug:init()
    addonData.debug:printBelow(addonData.debug.loglevel + 1) -- I want to see the debug module debug
    addonData.debug:logBelow(addonData.debug.loglevel + 1) -- also want it logged

    addonData.debug:registerCategory("event")
    db("event", "------------- NEW SESSION -------------")
    db("event", "loaded", event, ...)

    -- init modules
    addonData.settings:init()
    addonData.optionsgui:init()
    addonData.raid:init()
    addonData.gossip:init()
    addonData.summon:init()
    addonData.chat:init()
    addonData.monitor:init()
    addonData.util:init()

    -- register addon comms channel
    addonData.channel = "SteaSummon"
    local commsgood = C_ChatInfo.RegisterAddonMessagePrefix(addonData.channel)
    db("event","addon channel registered: ", commsgood)
    cprint("loaded")

    addonData.summon:showSummons()
  end
end