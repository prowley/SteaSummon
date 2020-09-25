local addonName, addonData = ...

local cw_spells = {} -- current summon spells being cast, module level because accessed in a callback
local g_self -- for callbacks

local summon = {
  waiting = {}, -- the summon list
  numwaiting = 0, -- the summon list length
  hasSummoned = false, -- when true we believe you more
  tainted = false, -- indicates player has cancelled something that's nothing to do with them
  myLocation = "", -- the location player is
  myZone = "", -- the zone player is
  location = "", -- area of zone summons are going to
  zone = "", -- the zone summons are going to
  summoningPlayer = "", -- the player currently being summoned

  init = function(self)
    addonData.debug:registerCategory("summon.display")
    addonData.debug:registerCategory("summon.waitlist")
    addonData.debug:registerCategory("summon.tick")
    addonData.debug:registerCategory("summon.misc")
    addonData.debug:registerCategory("summon.spellcast")
  end,

  ---------------------------------
  addWaiting = function(self, player)
    if self:findWaitingPlayerIdx(player) then
      self.waiting[3] = "requested"
      return
    end
    player = strsplit("-", player)
    db("summon.waitlist", "Making some space for ", player)
    self.numwaiting = self.numwaiting + 1

    -- priorities
    local inserted = false
    if SteaSummonSave.warlocks and addonData.util:playerCanSummon(player) then
      db("summon.waitlist", "Warlock " .. player .. " gets prio")
      table.insert(self.waiting, 1, {player, 0, "requested", "warlock"})
      inserted = true
    elseif addonData.settings:findPrioPlayer(player) ~= nil then
      for k, wait in pairs(self.waiting) do
        if not (SteaSummonSave.warlocks and addonData.util:playerCanSummon(wait[1]))
            and not addonData.settings:findPrioPlayer(wait[1]) then
          table.insert(self.waiting, k, {player, 0, "requested", "prioritized"})
          db("summon.waitlist", "Priority " .. player .. " gets prio")
          inserted = true
          break
        end
      end
    elseif addonData.settings:findShitlistPlayer(player) ~= nil then
      self.waiting[self.numwaiting] = {player, 0, "requested", "last"}
      inserted = true
    end

    if not inserted then
      local i
      local i = self.numwaiting
      while i > 1 and addonData.settings:findShitlistPlayer(self.waiting[i-1][1]) do
        db("summon.waitlist", self.waiting[i-1][1], "on shitlist, finding a better spot")
        i = i - 1
      end
      table.insert(self.waiting, i, {player, 0, "requested", ""})
    end

    db("summon.waitlist", player .. " added to waiting list")
    self:showSummons()
  end,

  ---------------------------------
  tick = function(self)
    --- update timers
    -- yea this is dumb, but time doesnt really work in wow
    -- so we count (rough) second ticks for how long someone has been waiting
    -- and need to update each individually (a global would wrap)
    for i, wait in pairs(self.waiting) do
      local player = wait[1]
      local time = wait[2]
      local status = wait[3]
      self.waiting[i] = {player, time + 1, status}
    end

    --- detect arriving players
    local players = {}
    for i, wait in pairs(self.waiting) do
      local player = wait[1]
      if addonData.util:playerClose(player) then
        db("summon.tick", player .. " detected close by")
        table.insert(players, player) -- yea, don't mess with tables while iterating on them
      end
    end

    for i, player in pairs(players) do
      self:arrived(player)
      addonData.gossip:arrived(player) -- let everyone else know
    end


    --- update our location
    self:setCurrentLocation()

    --- update display
    self:showSummons()
  end,

  ---------------------------------
  getWaiting = function(self) return self.waiting end,

  ---------------------------------
  showSummons = function(self)
    if InCombatLockdown() then
      return
    end

    if not SummonFrame then
      g_self = self
      local f = CreateFrame("Frame", "SummonFrame", UIParent, "AnimatedShineTemplate")--, "DialogBoxFrame")
      f:SetPoint("CENTER")
      f:SetSize(300, 250)
      f:SetScale(SteaSummonSave.windowSize)

      f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
        edgeSize = 16,
        insets = { left = 8, right = 6, top = 8, bottom = 8 },
      })
      f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue

      --- Movable
      f:SetMovable(true)
      f:SetClampedToScreen(true)
      f:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
          self:StartMoving()
        end
      end)
      local movefunc = function(self, button)
        f:StopMovingOrSizing()
        local pos = {}
        pos[1] = f:GetLeft()
        pos[2] = f:GetTop() - GetScreenHeight()
        pos[3] = f:GetRight() - GetScreenWidth()
        pos[4] = f:GetBottom()
        addonData.settings:setWindowPos(pos)
        if f:GetHeight() < 30 then
          ButtonFrame:Hide()
          ScrollFrame:Hide()
        else
          ScrollFrame:Show()
          ButtonFrame:Show()
        end
      end

      f:SetScript("OnMouseUp", movefunc)

      --- ScrollFrame
      local sf = CreateFrame("ScrollFrame", "ScrollFrame", SummonFrame, "UIPanelScrollFrameTemplate")
      sf:SetPoint("LEFT", 8, 0)
      sf:SetPoint("RIGHT", -40, 0)
      sf:SetPoint("TOP", 0, -32)
      sf:SetScale(0.5)

      addonData.buttonFrame = CreateFrame("Frame", "ButtonFrame", SummonFrame)
      addonData.buttonFrame:SetSize(sf:GetSize())
      addonData.buttonFrame:SetScale(SteaSummonSave.listSize)
      sf:SetScrollChild(addonData.buttonFrame)

      --- Table of summon info
      addonData.buttons = {}
      for i=1, 36 do
        self:createButton(i)
      end

      --- Setup Next button
      addonData.buttons[36].Button:SetPoint("TOPLEFT","SummonFrame","TOPLEFT", -10, 10)
      addonData.buttons[36].Button:SetText("Next")

      --- Resizable
      f:SetResizable(true)
      f:SetMinResize(80, 25)
      f:SetClampedToScreen(true)

      local rb = CreateFrame("Button", "ResizeButton", SummonFrame)
      rb:SetPoint("BOTTOMRIGHT", -6, 7)
      rb:SetSize(8, 8)

      rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
      rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
      rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

      rb:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
          f:StartSizing("BOTTOMRIGHT")
          self:GetHighlightTexture():Hide() -- more noticeable
        end
      end)
      rb:SetScript("OnMouseUp", movefunc)

      local pos = addonData.settings:getWindowPos()
      if pos then
        f:SetPoint("TOPLEFT", UIParent, pos[1], pos[2])
        f:SetPoint("BOTTOMRIGHT", UIParent, pos[3], pos[4])
        if f:GetHeight() < 45 then
          ButtonFrame:Hide()
          ScrollFrame:Hide()
        else
          ScrollFrame:Show()
          ButtonFrame:Show()
        end
      end

      --- Text items
      f.logo = f:CreateFontString(nil,"ARTWORK")
      f.logo:SetFont("Fonts\\ARIALN.ttf", 40, "OUTLINE")
      f.logo:SetPoint("CENTER",0,0)
      f.logo:SetAlpha(.2)
      f.logo:SetText("|cfffff000SteaSummon")

      f.location = f:CreateFontString(nil,"ARTWORK")
      f.location:SetFont("Fonts\\ARIALN.ttf", 8, "OUTLINE")
      f.location:SetPoint("TOPLEFT","SummonFrame", "TOPLEFT", 70, -8)
      f.location:SetAlpha(.5)
      f.location:SetText("")

      f.destination = f:CreateFontString(nil,"ARTWORK")
      f.destination:SetFont("Fonts\\ARIALN.ttf", 8, "OUTLINE")
      f.destination:SetPoint("TOPLEFT","SummonFrame", "TOPLEFT", 70, 0)
      f.destination:SetAlpha(.5)
      f.destination:SetText("")

      f.status = f:CreateFontString(nil,"ARTWORK")
      f.status:SetFont("Fonts\\ARIALN.ttf", 8, "OUTLINE")
      f.status:SetPoint("TOPLEFT","SummonFrame", "TOPLEFT", -30, -20)
      f.status:SetAlpha(.5)
      f.status:SetText("")

      --- final sanity check, catch screen size change etc.
      db("Height = ", f:GetHeight(), "Screen: ", GetScreenHeight(), " Width = ", f:GetWidth(), " screen ", GetScreenWidth())
      if f:GetHeight() >= GetScreenHeight() or f:GetWidth() >= GetScreenWidth() then
        f:SetPoint("TOPLEFT", UIParent, 300, 250)
        f:SetPoint("BOTTOMRIGHT", UIParent, 300, 250)
      end
    end

    --- update buttons
    local next = false
    for i=1, 35 do
      local player = nil
      local summonClick = nil
      local cancelClick = nil

      if self.waiting[i] ~= nil then
        self:enableButton(i)
        player = self.waiting[i][1]
        addonData.buttons[i].Button:SetText(player)
        _, class = UnitClass(player)
        r,g,b,_ = GetClassColor(class)
        addonData.buttons[i].Status["FS"]:SetTextColor(r,g,b, 1)
        if (addonData.util:playerCanSummon()) then
          addonData.buttons[i].Button:SetAttribute("macrotext", "/target " .. player .. "\n/cast Ritual of Summoning")
        end
      else
        self:enableButton(i, false)
      end

      local z = GetZoneText()
      local l = GetMinimapZoneText()

      if (addonData.util:playerCanSummon()) then
        summonClick = function(otherself, button, worked)
          if button == "LeftButton" and worked then
            db("summoning ", player)
            addonData.gossip:status(player, "pending")
            addonData.chat:raid(SteaSummonSave.raidchat, player)
            addonData.chat:say(SteaSummonSave.saychat, player)
            addonData.chat:whisper(SteaSummonSave.whisperchat, player)
            self.summoningPlayer = player
            self:summoned(player)
            self:setDestination(z, l)
            addonData.gossip:destination(z, l)
            self.hasSummoned = true
          end
        end
        addonData.buttons[i].Button:SetScript("OnMouseUp", summonClick)
      end

      --- Cancel Button
      -- Can cancel from own UI
      -- Cancelling self sends msg to others
      -- If summoning warlock, can cancel and send msg to others
      cancelClick = function(otherself, button, worked)
        if button == "LeftButton" and worked then
          local me, void = UnitName("player")
          db(me)
          if hasSummoned or player == me then
            addonData.gossip:arrived(player)
          else
            self.tainted = true
          end
          self:arrived(player)
        end
      end

      addonData.buttons[i].Cancel:SetScript("OnMouseUp", cancelClick)

      --- Next Button
      if self.waiting[i]  then
        if not next and self.waiting[i][3] == "requested" and addonData.util:playerCanSummon() then
          next = true
          addonData.buttons[36].Button:SetAttribute("macrotext", "/target " .. player .. "\n/cast Ritual of Summoning")
          addonData.buttons[36].Button:SetScript("OnMouseUp", summonClick)
          addonData.buttons[36].Button:Show()
        end

        addonData.buttons[i].Time["FS"]:SetText(string.format(SecondsToTime(self.waiting[i][2])))
        local strwd = addonData.buttons[i].Time["FS"]:GetStringWidth()
        addonData.buttons[i].Time:SetWidth(strwd+10)
        addonData.buttons[i].Status["FS"]:SetText(self.waiting[i][3])
      end
    end


    if not next then
      -- all summons left are pending, disable the next button
      addonData.buttons[36].Button:Hide()
    end

    --- show summon window
    local show = false
    if addonData.settings:showWindow() or (addonData.settings:showActive() and self.numwaiting > 0) then
      show = true
    elseif addonData.settings:showJustMe() then
      local me, void = UnitName("player")

      for i,wait in pairs(self.waiting) do
        local player = wait[1]
        if player == me then
          show = true
        end
      end
    end

    if show then
        SummonFrame:Show()
      if self.numwaiting > 0 then
        addonData.monitor:start() -- start ui update tick
      end
    else
      SummonFrame:Hide()
      addonData.monitor:stop() -- stop ui update tick
    end

    if self.numwaiting == 0 then
      self.hasSummoned = false
    end
  end,

  ---------------------------------
  createButton = function(self, i)
    -- Summon Button
    local bw = 80
    local bh = 25
    local padding = 40

    local parent = addonData.buttonFrame
    if i == 36 then
      parent = SummonFrame
    end

    addonData.buttons[i] = {}
    addonData.buttons[i].Button = CreateFrame("Button", "SummonButton"..i, parent, "SecureActionButtonTemplate");
    addonData.buttons[i].Button:SetPoint("TOPLEFT","ButtonFrame","TOPLEFT", padding,-((i*bh)-15))
    addonData.buttons[i].Button:SetWidth(bw)
    addonData.buttons[i].Button:SetHeight(bh)
    addonData.buttons[i].Button:SetText("Stea")
    addonData.buttons[i].Button:SetNormalFontObject("GameFontNormalSmall")
    addonData.buttons[i].Buttonntex = addonData.buttons[i].Button:CreateTexture()
    addonData.buttons[i].Buttonntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
    addonData.buttons[i].Buttonntex:SetTexCoord(0, 0.625, 0, 0.6875)
    addonData.buttons[i].Buttonntex:SetAllPoints()
    addonData.buttons[i].Button:SetNormalTexture(addonData.buttons[i].Buttonntex)
    addonData.buttons[i].Buttonhtex = addonData.buttons[i].Button:CreateTexture()
    addonData.buttons[i].Buttonhtex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
    addonData.buttons[i].Buttonhtex:SetTexCoord(0, 0.625, 0, 0.6875)
    addonData.buttons[i].Buttonhtex:SetAllPoints()
    addonData.buttons[i].Button:SetHighlightTexture(addonData.buttons[i].Buttonhtex)
    addonData.buttons[i].Buttonptex = addonData.buttons[i].Button:CreateTexture()
    addonData.buttons[i].Buttonptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
    addonData.buttons[i].Buttonptex:SetTexCoord(0, 0.625, 0, 0.6875)
    addonData.buttons[i].Buttonptex:SetAllPoints()
    addonData.buttons[i].Buttonpdis = addonData.buttons[i].Button:CreateTexture()
    addonData.buttons[i].Buttonpdis:SetTexture("Interface/Buttons/UI-Panel-Button-Disabled")
    addonData.buttons[i].Buttonpdis:SetTexCoord(0, 0.625, 0, 0.6875)
    addonData.buttons[i].Buttonpdis:SetAllPoints()
    addonData.buttons[i].Button:SetDisabledTexture(addonData.buttons[i].Buttonpdis)
    addonData.buttons[i].Button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    addonData.buttons[i].Button:SetPushedTexture(addonData.buttons[i].Buttonptex)
    addonData.buttons[i].Button:SetAttribute("type1", "macro");
    addonData.buttons[i].Button:SetAttribute("macrotext", "")
    --ConsSummoner.LootFrame["TopGuildFrame"]:SetHeight(20+h*25)

    if i < 36 then -- last button we use for next summon, so don't want these
      -- Cancel
      addonData.buttons[i].Cancel = CreateFrame("Button", "CancelButton"..i, parent, "UIPanelCloseButtonNoScripts")
      addonData.buttons[i].Cancel:SetWidth(bw/3)
      addonData.buttons[i].Cancel:SetHeight(bh)
      addonData.buttons[i].Cancel:SetText("X")
      addonData.buttons[i].Cancel:SetPoint("TOPLEFT","ButtonFrame","TOPLEFT", 10,-((i*bh)-15))

      -- Wait Time
      addonData.buttons[i].Time = CreateFrame("Frame", "SummonWaitTime"..i, addonData.buttonFrame)
      addonData.buttons[i].Time:SetWidth(50)
      addonData.buttons[i].Time:SetHeight(bh)
      addonData.buttons[i].Time:SetPoint("TOPLEFT", addonData.buttonFrame, "TOPLEFT",bw + padding + 90,-((i*bh)-15))
      addonData.buttons[i].Time:SetBackdrop( {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 5, edgeSize = 15, insets = { left = 1, right = 1, top = 1, bottom = 1 }
      });

      addonData.buttons[i].Time["FS"] = addonData.buttons[i].Time:CreateFontString("TimeText"..i,"ARTWORK", "ChatFontNormal")
      addonData.buttons[i].Time["FS"]:SetParent(addonData.buttons[i].Time)
      addonData.buttons[i].Time["FS"]:SetPoint("TOP",addonData.buttons[i].Time,"TOP",0,0)
      addonData.buttons[i].Time["FS"]:SetWidth(150)
      addonData.buttons[i].Time["FS"]:SetHeight(25)
      addonData.buttons[i].Time["FS"]:SetJustifyH("CENTER")
      addonData.buttons[i].Time["FS"]:SetFontObject("GameFontNormalSmall")
      addonData.buttons[i].Time["FS"]:SetText(string.format(SecondsToTime(0)))

      -- Status
      addonData.buttons[i].Status = CreateFrame("Frame", "SummonStatus"..i, addonData.buttonFrame)
      addonData.buttons[i].Status:SetWidth(bw)
      addonData.buttons[i].Status:SetHeight(bh)
      addonData.buttons[i].Status:SetPoint("TOPLEFT", addonData.buttonFrame, "TOPLEFT",bw + padding + 5,-((i*bh)-15))
      addonData.buttons[i].Status:SetBackdrop( {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 5, edgeSize = 15, insets = { left = 1, right = 1, top = 1, bottom = 1 }
      });
      addonData.buttons[i].Status["FS"] = addonData.buttons[i].Status:CreateFontString("StatusText"..i,"ARTWORK", "ChatFontNormal")
      addonData.buttons[i].Status["FS"]:SetParent(addonData.buttons[i].Status)
      addonData.buttons[i].Status["FS"]:SetPoint("TOP",addonData.buttons[i].Status,"TOP",0,0)
      addonData.buttons[i].Status["FS"]:SetWidth(160)
      addonData.buttons[i].Status["FS"]:SetHeight(25)
      addonData.buttons[i].Status["FS"]:SetJustifyH("CENTER")
      addonData.buttons[i].Status["FS"]:SetFontObject("GameFontNormalSmall")
      addonData.buttons[i].Status["FS"]:SetTextColor(1,1,1)
      addonData.buttons[i].Status["FS"]:SetText("Waiting")
    end
  end,

  ---------------------------------
  enableButton = function(self, idx, enable)
    if enable == nil then
      enable = true
    end

    if enable then
      if not InCombatLockdown() then
        addonData.buttons[idx].Button:Show()
        addonData.buttons[idx].Cancel:Show()
        addonData.buttons[idx].Time:Show()
        addonData.buttons[idx].Status:Show()
        addonData.buttons[idx].Button:Enable()
      end
    else
      if not InCombatLockdown() then
        addonData.buttons[idx].Button:Hide()
        addonData.buttons[idx].Cancel:Hide()
        addonData.buttons[idx].Time:Hide()
        addonData.buttons[idx].Status:Hide()
        addonData.buttons[idx].Button:Enable()
      end
    end
  end,

  ---------------------------------
  enableButtons = function(self, enable)
    for i=1, 35 do
      self:enableButton(i, enable)
    end
  end,

  ---------------------------------
  findWaitingPlayerIdx = function(self, player)
    for i, wait in pairs(self.waiting) do
      if wait[1] == player then
        return i
      end
    end
    return nil
  end,

  ---------------------------------
  findWaitingPlayer = function(self, player)
    local idx = self:findWaitingPlayerIdx(player)
    if idx then
      return self.waiting[idx]
    end
    return nil
  end,

  ---------------------------------
  summoned = function(self, player)
    -- update status
    waitEntry = self:findWaitingPlayer(player)
    if waitEntry ~= nil then
      db("summon.waitlist", "a summon is pending for " .. player)
      waitEntry[3] = "pending"
    end
  end,

  ---------------------------------
  status = function(self, player, status)
    -- update status
    waitEntry = self:findWaitingPlayer(player)
    if waitEntry ~= nil then
      db("summon.waitlist", "status changed to", status, "for", player)
      waitEntry[3] = status
    end
  end,

  ---------------------------------
  arrived = function(self, player)
    self:remove(player)
  end,

  ---------------------------------
  summonFail = function(self)
    local idx = self:findWaitingPlayerIdx(self.summoningPlayer)
    if idx then
      db("summon.waitlist", "something went wrong, resetting status of " .. self.summoningPlayer .. " to requested")
      self.waiting[idx][3] = "requested"
      addonData.gossip:status(self.summoningPlayer, "requested")
    end
  end,

  offline = function(self, offline, player)
    local idx = self:findWaitingPlayerIdx(player)
    if idx then
      local state = ""
      if offline then
        db("summon.waitlist", "setting status of " .. player .. " to offline")
        state = "offline"
      else
        if self.waiting[idx][3] == "offline" then
          db("summon.waitlist", "setting status of " .. player .. " from offline to waiting")
          state = "waiting"
        end
      end
      if state ~= "" then
        self.waiting[idx][3] = state
      end
    end
  end,

  remove = function(self, player)
    local idx = self:findWaitingPlayerIdx(player)
    if idx then
      db("summon.waitlist", "removing", player, "from the waiting list")
      table.remove(self.waiting, idx)
      self.numwaiting = self.numwaiting - 1
    end
  end,

  dead = function(self, dead, player)
    local idx = self:findWaitingPlayerIdx(player)
    if idx then
      local state = ""
      if dead then
        state = "dead"
        db("summon.waitlist", "setting status of", player, "to dead")
      else
        if self.waiting[idx][3] == "dead" then
          db("summon.waitlist", "setting status of", player, "from dead to waiting")
          state = "waiting"
        end
      end
      if state ~= "" then
        self.waiting[idx][3] = state
      end
    end
  end,

  ---------------------------------
  callback = function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
      -- entered combat, stop everything or we might get tainted
      SummonFrame:Hide()
    end
    if event == "PLAYER_REGEN_ENABLED" then
      -- start things up again, nothing to do
    end
  end,

  ---------------------------------
  getCurrentLocation = function(self)
    local z = GetZoneText()
    local l = GetMinimapZoneText()
    return z,l
  end,

  ---------------------------------
  setCurrentLocation = function(self)
    self.myZone = GetZoneText()
    self.myLocation = GetMinimapZoneText()

    if self.myZone == self.zone and self.myLocation == self.location then
      SummonFrame.destination:SetTextColor(0,1,0,.5)
      SummonFrame.location:SetTextColor(0,1,0,.5)
    else
      SummonFrame.destination:SetTextColor(1,1,1,.5)
      SummonFrame.location:SetTextColor(1,0,0,.5)
    end

    SummonFrame.location:SetText("Location: " .. self.myZone .. ", " .. self.myLocation)
  end,

  ---------------------------------
  setDestination = function(self, zone, location)
    self.location = location
    self.zone = zone

    db("summon.misc", "setting destination: ", location, " in ", zone)
    SummonFrame.destination:SetText("Destination: " .. self.location .. ", " .. self.zone)
    end,

  ---------------------------------
  castWatch = function(self, event, target, castUID, spellId, ...)
    db("summon.spellcast", event, " ", target, castUID, spellId, ...)

    local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo(spellId)
    db("summon.spellcast", name, rank, castTime, minrange, maxrange)

    -- these events can get posted up to 3 times (at least testing on myself) player, raid1 (me), target
    -- observed:
    -- when target is you, get target message. otherwise no
    -- guesses:
    -- you get target if target is casting
    -- you get player if you are casting
    -- you get raid1 if there is a raid (not party) if someone in your raid is casting (even if it is you) *** if true this is very cool

    -- only interested in summons cast by player for now
    if name ~= "Ritual of Summoning" or string.sub(target,1,4) == "raid" or target ~= "player" then
      return
    end

    --db("summon.spellcast", "cast info: ", UnitCastingInfo(unit)) internal blizz call? Their code def calls this

    if event == "UNIT_SPELLCAST_START" then
      -- cast started, register this
      -- {raider}
      --local cast = cw_spells[castUID]
      --if not cast then
      --cast = {UnitName(target)}
      --cw_spells[castUID] = cast
      --db(cast[1])
      --end

    elseif event == "UNIT_SPELLCAST_CHANNEL_UPDATE" then
      -- never seen this
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
      -- end of cast, into channel
    elseif event == "UNIT_SPELLCAST_DELAYED" then
      -- presumably if you get hit while casting
    elseif event == "UNIT_SPELLCAST_STOP"
        or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
      -- this is a normal end of cast
    elseif event == "UNIT_SPELLCAST_INTERRUPTED"
        or event == "UNIT_SPELLCAST_FAILED" then
      -- something went wrong
      -- no castid for stop lol
      addonData.summon.summonFail(g_self)
    end
  end,
}

addonData.summon = summon
