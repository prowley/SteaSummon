-- chat message interpretation

local addonName, addonData = ...

local chat = {
  init = function(self)
    addonData.debug:registerCategory("chat")
  end,

  callback = function (self, event, msg, servername, ...)
    local me, void = UnitName("player")

    -- don't want randos adding themselves
    player, server = strsplit("-", servername)
    if event == "CHAT_MSG_SAY" and player ~= me then
      return
    end

    db("chat", "testing chat for keywords")

    if player == me then
      if msg and msg:find("!SS") == 1 then
        local prmpt, cmd, args = strsplit(" ", msg)
        if cmd == nil then cmd = "list" end
        if args == nil then args = "" end
        cmd = string.lower(cmd)

        db("chat","Received command : " .. cmd .. " " .. args)
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

        if cmd == "add" then
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
        addonData.summon:remove(name)
      elseif addonData.settings:findSummonWord(msg) then
        -- someone wants a summon
        name, server = strsplit("-", servername)
        db("chat","adding ", name, "to summon list")

        if IsInGroup(player) or player == me then
          addonData.summon:addWaiting(name, true)
          if event == "CHAT_MSG_WHISPER" then
            addonData.gossip:add(player)
          end
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

  sendChat = function(self, msg, channel, channel2, to)
    db("sendChat ", msg, " ", channel, " ", to)
    if msg ~= nil and ms ~= "" then
      -- substitute variables in message
      local patterns = {["%%p"] = to, ["%%l"] = GetMinimapZoneText(), ["%%z"] = GetZoneText()}
      for key, val in pairs(patterns) do
        msg = string.gsub(msg, key, val)
      end

      SendChatMessage(msg,channel,channel2,to)
    end
  end
}

addonData.chat = chat