-- chat message interpretation

local addonName, addonData = ...

local chat = {
  callback = function (self, event, msg, servername, ...)
    local me, void = UnitName("player")

    -- don't want randos adding themselves
    player, server = strsplit("-", servername)
    if event == "CHAT_MSG_SAY" and player ~= me then
      return
    end

    if player == me then
      if msg and msg:find("!SS") == 1 then
        local prmpt, cmd, args = strsplit(" ", msg)
        if cmd == nil then cmd = "list" end
        if args == nil then args = "" end
        cmd = string.lower(cmd)
        args = string.lower(args)

        db("Received command : " .. cmd .. " " .. args)
        if cmd == "list" then
          local waitlist = addonData.summon:getWaiting()
          cprint("Summon wait list")
          count = 0
          for i,waiting in pairs(waitlist) do
            cprint(waiting[1], " waiting: ", waiting[2], " seconds")
            count = count + 1
          end
          cprint(count, " waiting")

        end

        if cmd == "debug" then
          if args == "on" then addonData.settings:debug(true)
          elseif args == "off" then addonData.settings:debug(false)
          else addonData.settings:debug(not addonData.settings:debug())
          end

          local offon = "OFF"
          if addonData.settings:debug() then offon = "ON" end
          cprint("Debugging: ", offon)
        end
      end
    end

    if msg and addonData.settings:findSummonWord(msg) then
      -- someone wants a summon
      name, server = strsplit("-", servername)
      db("adding ", name, "to summon list")

      addonData.summon:addWaiting(name)
    end
  end,

  raid = function(self, msg, player)
    self:sendChat(msg, "RAID", "RAID", player)
  end,

  say = function(self, msg)
    self:sendChat(msg, "SAY", "SAY", player)
  end,

  whisper = function(self, msg, to, player)
    self:sendChat(msg, "WHISPER", to)
  end,

  sendChat = function(self, msg, channel, to)
    db("sendChat ", msg, " ", channel, " ", to)
    if msg ~= nil and ms ~= "" then
      -- substitute variables in message
      local patterns = {["%%p"] = player, ["%%l"] = GetMinimapZoneText(), ["%%z"] = GetZoneText()}
      for key, val in pairs(patterns) do
        msg = string.gsub(msg, key, val)
      end

      SendChatMessage(msg,channel,nil,to)
    end
  end
}

addonData.chat = chat