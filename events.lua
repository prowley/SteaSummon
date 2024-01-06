-- event setup

local addonName, addonData = ...
local call = {}

local frame

local function callback(self, event, ...)
  if call[event] ~= nil then
    call[event](self, event, ...)
  end
end

local function playerEnter()
  db("event.event","player entering world")

  -- register events
  for k,_ in pairs(call) do
    if k ~= "ADDON_LOADED" then
      db("event.event","registering event", k)
      frame:RegisterEvent(k)
    end
  end
end

local function loaded(_, event, ...)
  local name = ...

  -- if it this addon
  if (name == addonName) then
    -- this the first point that settings are loaded, and therefore the "debug" flag
    -- so db won't log anything before now, also not safe to call category debug before now
    addonData.debug:init()
    addonData.debug:printBelow(addonData.debug.loglevel + 1) -- I want to see the debug module debug
    addonData.debug:logBelow(addonData.debug.loglevel + 1) -- also want it logged

    addonData.debug:registerCategory("event.event")
    db("event.event", "------------- NEW SESSION -------------")
    db("event.event", "loaded", event, ...)

    -- init modules, some of these just set up debug categories
    addonData.settings:init()
    addonData.optionsgui:init()
    addonData.gossip:init()
    addonData.raid:init()
    addonData.monitor:init()
    addonData.summon:init()
    addonData.chat:init()
    addonData.util:init()
    addonData.buffs:init()
    addonData.alt:init()
    addonData.appbutton:init()

    -- wait to set up debug categories until all categories are registered
    -- otherwise the category or its children may not be registered for chat debug messages
    addonData.debug:chatCat("summon.waitlist")
    addonData.debug:chatCat("summon.spellcast")
    addonData.debug:chatCat("summon.display")
    addonData.debug:chatCat("gossip")
    addonData.debug:chatCat("raid")
    addonData.debug:chatCat("alt")
    addonData.debug:chatCat("buffs")
    addonData.debug:chatCat("minimap")
    addonData.debug:chatCat("util")
    addonData.debug:chatCatSwitch(true) -- strictly this is unnecessary, but I want to see the output

    cprint("loaded version", GetAddOnMetadata(addonName, "Version"))
  end
end

local function start()
  db("start")

  -- build callback table
  call["ADDON_LOADED"] = loaded
  call["PLAYER_ENTERING_WORLD"] = playerEnter
  call["PLAYER_LOGOUT"] = addonData.settings.saveOnLogout
  call["CHAT_MSG_PARTY"] = addonData.chat.callback
  call["CHAT_MSG_PARTY_LEADER"] = addonData.chat.callback
  call["CHAT_MSG_RAID"] = addonData.chat.callback
  call["CHAT_MSG_RAID_LEADER"] = addonData.chat.callback
  call["CHAT_MSG_ADDON"] = addonData.gossip.callback
  call["CHAT_MSG_SAY"] = addonData.chat.callback
  call["CHAT_MSG_WHISPER"] = addonData.chat.callback
  call["PARTY_LEADER_CHANGED"] = addonData.raid.callback
  call["GROUP_ROSTER_UPDATE"] = addonData.raid.callback
  call["RAID_ROSTER_UPDATE"] = addonData.raid.callback
  call["PLAYER_REGEN_DISABLED"] = addonData.summon.callback
  call["UNIT_SPELLCAST_START"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_STOP"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_FAILED"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_INTERRUPTED"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_DELAYED"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_CHANNEL_START"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_CHANNEL_UPDATE"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_CHANNEL_STOP"] = addonData.summon.castWatch
  call["UNIT_SPELLCAST_SUCCEEDED"] = addonData.summon.castWatch
  call["ITEM_PUSH"] = addonData.summon.bagPushShardCheck
  call["PARTY_INVITE_REQUEST"] = addonData.raid.acceptInvites

  -- under observation
  call["UNIT_SPELLCAST_FAILED_QUIET"] = addonData.monitor.callback

   -- set up the load event
  frame = CreateFrame("Frame")
  frame:RegisterEvent("ADDON_LOADED")
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", callback)
end

addonData.start = start
