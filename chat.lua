-- chat message interpretation

local _, addonData = ...
local L = LibStub("AceLocale-3.0"):GetLocale("SteaSummon")

local chat = {
  init = function(_)
    addonData.debug:registerCategory("chat")
  end,

  callback = function (_, event, msg, servername, ...)
    local me, _ = UnitName("player")

    -- don't want randos adding themselves
    player, server = strsplit("-", servername)
    if event == "CHAT_MSG_SAY" and player ~= me then
      return
    end

    db("chat", "testing chat for keywords")

    if player == me then
      if msg and msg:find("!SS") == 1 then
        local _, cmd, args = strsplit(" ", msg)
        if cmd == nil then cmd = "list" end
        if args == nil then args = "" end
        cmd = string.lower(cmd)

        db("chat","Received command : " .. cmd .. " " .. args)
        if cmd == "list" then
          local waitlist = addonData.summon:getWaiting()
          cprint(L["Summon waiting list"])
          count = 0

          for _,waiting in pairs(waitlist) do
            local pats = {["%%name"] = waiting[1], ["%%number"] = waiting[2]}
            local s = L["%name waiting: %number seconds"]
            s = tstring(s, pats)
            cprint(s)
            count = count + 1
          end
          
          local pats = {["%%count"] = count}
          local s = L["%count waiting"]
          s = tstring(s, pats)
          cprint(s)

        end

        if cmd == L["debug"] then
          if args == L["on"] then addonData.settings:debug(true)
          elseif args == L["off"] then addonData.settings:debug(false)
          else addonData.settings:debug(not addonData.settings:debug())
          end

          local offon = L["off"]
          if addonData.settings:debug() then offon = L["on"] end
          cprint("Debugging: ", offon)
        end

        if cmd == L["add"] then
          -- add someone to list
          if args ~= "" then
            addonData.summon:addWaiting(args)
          end
        end
      end
    end

    if msg then
      if string.sub(msg, 1,1) == "-" and addonData.settings:findSummonWord(string.sub(msg, 2)) then
        name, server = strsplit("-", servername)
        addonData.gossip:arrived(name)
      elseif addonData.settings:findSummonWord(msg) then
        -- someone wants a summon
        name, server = strsplit("-", servername)
        db("chat","adding ", name, "to summon list")

        if IsInGroup(player) or (player == me and addonData.settings:debug()) then
          addonData.gossip:add(player, event == "CHAT_MSG_WHISPER" )
          --addonData.summon:addWaiting(name, true)
        end
      end
    end
  end,

  raid = function(self, msg, player)
    self:sendChat(msg, "RAID", "RAID", player)
  end,

  say = function(self, msg, player)
    self:sendChat(msg, "SAY", "SAY", player)
  end,

  whisper = function(self, msg, player)
    self:sendChat(msg, "WHISPER", player, player)
  end,

  sendChat = function(_, msg, channel, channel2, to)
    db("chat", "sendChat ", msg, " ", channel, " ", to)
    if msg ~= nil and ms ~= "" then
      -- substitute variables in message
      local patterns = {["%%p"] = to, ["%%l"] = GetMinimapZoneText(), ["%%z"] = GetZoneText()}
      msg = tstring(msg, patterns)

      SendChatMessage(msg,channel,channel2,to)
    end
  end
}

addonData.chat = chat