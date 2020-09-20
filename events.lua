-- event setup

local addonName, addonData = ...
local call = {}

function start()
  db("start")

  -- build callback table
  call["ADDON_LOADED"] = loaded
  call["CHAT_MSG_PARTY"] = addonData.chat.callback
  call["CHAT_MSG_PARTY_LEADER"] = addonData.chat.callback
  call["CHAT_MSG_RAID"] = addonData.chat.callback
  call["CHAT_MSG_RAID_LEADER"] = addonData.chat.callback
  call["CHAT_MSG_ADDON"] = addonData.gossip.callback
  call["CHAT_MSG_SAY"] = addonData.chat.callback
  -- apparently doesnt exist call["PARTY_CONVERTED_TO_RAID"] = addonData.raid.callback
  call["PARTY_LEADER_CHANGED"] = addonData.raid.callback
  -- not exist call["GROUP_ROSTER_CHANGED"] = addonData.raid.callback
  call["GROUP_ROSTER_UPDATE"] = addonData.raid.callback
  call["RAID_ROSTER_UPDATE"] = addonData.raid.callback
  call["NAME_PLATE_UNIT_ADDED"] = addonData.raid.callback
  call["NAME_PLATE_UNIT_REMOVED"] = addonData.raid.callback
  call["PLAYER_REGEN_DISABLED"] = addonData.summon.callback
  call["PLAYER_REGEN_ENABLED"] = addonData.summon.callback

   -- set up the load event
  frame = CreateFrame("Frame")
  frame:RegisterEvent("ADDON_LOADED")
  frame:SetScript("OnEvent", callback)
end

function callback(self, event, ...)
  if call[event] ~= nil then
    call[event](self, event, ...)
  end
end

function loaded(self, event, ...)
  local name = ...

  -- if it this addon
  if (name == addonName) then
    db("loaded", event, ...)
    -- init settings
    addonData.settings:init()
    addonData.optionsgui:init()

    local playerClass, englishClass = UnitClass("player")
  
    if (playerClass ~= "Warlock") then
      -- only work for warlocks
      cprint("loaded but disabled")
    else
      -- register other events
      for k,v in pairs(call) do
        if k ~= "ADDON_LOADED" then
          db("registering event", k)
          frame:RegisterEvent(k)
        end
      end
      
      -- create monitor callback
      db("setting up monitor callback")
      addonData.monitor:init()

      -- register addon comms channel
      addonData.channel = "SteaSummon"
      local commsgood = C_ChatInfo.RegisterAddonMessagePrefix(addonData.channel)
      db("addon channel registered: ", commsgood)
      cprint("loaded")

      addonData.gossip:initialize() -- this will get you a head start when doing a log out/in cycle
    end
  end
end