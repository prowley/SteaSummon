-- debug stuff
-- it's not long before printing every debug message makes debugging AND doing stuff in game impossible
-- ephemeral strings to chat is not a very good replacement for a proper debug log
-- this module is about limiting debug output to that of current interest and / or storing logout surviving logs
-- later, it might be about directing that output to another frame

-- categories can be dot delimited into sub categories e.g. "example.subexample"
-- so that any request to view category example will also list example.subexample (example need never actually be
-- logged or displayed)
-- when registering a child category before its parent, all ancestors are also registered with the same log flag
-- if you want to create gaps in what is logged in a category tree, take care with how you register categories
-- e.g.
-- registerCategory("example.subexample") -- example and subexample logged
-- registerCategory("example.subexample.notofinterest", false) -- example.subexample.notofinterest not logged
-- registerCategory("example.subexample.notofinterest.butthisis") example.subexample.notofinterest.butthisis logged

local addonName, addonData = ...
local aboveLogLevel = 1000001

-- local
local debug = {
  loglevel = aboveLogLevel, -- our logging level, set just above default log print level
  l_logBelow = aboveLogLevel, -- don't store debug module messages by default either
  l_logAbove = -1,
  l_printAbove = -1,
  l_printBelow = aboveLogLevel,
  chatFlag = true,
  chatCats = {},
  category = {},
  categoryLog = {},
  categoryChildren = {},

  init = function(self)
    if not SteaDEBUG or not SteaDEBUG.log then
      self:reset()
    end
    if SteaDEBUG.loglength == nil then
      SteaDEBUG.loglength = 3000
    end

    if #SteaDEBUG.log > SteaDEBUG.loglength then
      for i = #SteaDEBUG.log, SteaDEBUG.loglength, -1 do
        table.remove(SteaDEBUG.log)
      end
    end

    local f = CreateFrame("Frame", "DBFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate, AnimatedShineTemplate")
    f:SetPoint("CENTER")
    f:SetSize(300, 250)

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
      --local pos = {}
      --pos[1] = f:GetLeft()
      --pos[2] = f:GetTop() - GetScreenHeight()
      --pos[3] = f:GetRight() - GetScreenWidth()
      --pos[4] = f:GetBottom()
      --SteaDEBUG.wpos = pos
    end
    f:SetScript("OnMouseUp", movefunc)

    --- Resizable
    f:SetResizable(true)
    f:SetResizeBounds(150, 100)
    f:Hide()
  end,

  buildContent = function(self)
    -- this is kicked off by show, see above for why
    local rb = CreateFrame("Button", "DBResizeButton", DBFrame)
    rb:SetPoint("BOTTOMRIGHT", -6, 7)
    rb:SetSize(16, 16)

    rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    rb:SetScript("OnMouseDown", function(self, button)
      if button == "LeftButton" then
        DBFrame:StartSizing("BOTTOMRIGHT")
        DBResizeButton:GetHighlightTexture():Hide() -- more noticeable
      end
    end)
    rb:SetScript("OnMouseUp", function(self, button)
      DBFrame:StopMovingOrSizing()
      DBResizeButton:GetHighlightTexture():Show()
      DBLog:SetWidth(DBFrame:GetWidth())
      DBLog:SetHeight(DBFrame:GetHeight())
    end)

    --- ScrollFrame
    local sf = CreateFrame("ScrollFrame", "DBScrollFrame", DBFrame, "UIPanelScrollFrameTemplate")
    sf:SetPoint("LEFT", 16, 0)
    sf:SetPoint("RIGHT", -32, 0)
    sf:SetPoint("TOP", 0, -16)
    sf:SetPoint("BOTTOM", rb, "TOP", 0, 0)

    local dbl = CreateFrame("Frame", "DBLog", DBFrame, "AnimatedShineTemplate")
    dbl:SetWidth(DBFrame:GetWidth())
    dbl:SetHeight(DBFrame:GetHeight())
    sf:SetScrollChild(dbl)

    dbl:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
      edgeSize = 16,
      insets = { left = 8, right = 6, top = 8, bottom = 8 },
    })
    dbl:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue

    -- add lines of log
    local cat = CreateFrame("Frame", "CategoryLinesFrame", DBLog, "AnimatedShineTemplate")
    local x,y = dbl:GetSize()
    local cx = x * 0.2
    db(addonData.debug.loglevel, cx)
    cat:SetSize(cx, y)
    cat:SetPoint("TOPLEFT", dbl, "TOPLEFT", 0, 0)
    cat:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
      edgeSize = 16,
      insets = { left = 8, right = 6, top = 8, bottom = 8 },
    })
    cat:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue

    local line = CreateFrame("Frame", "LogLinesFrame", DBLog, "AnimatedShineTemplate")
    local lx = x * 0.6
    line:SetSize(lx, y)
    line:SetPoint("TOPRIGHT", CategoryLinesFrame, "TOPRIGHT", 0, 0)
    line:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
      edgeSize = 16,
      insets = { left = 8, right = 6, top = 8, bottom = 8 },
    })
    line:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue

    for i=1, 40 do
      cat[i] = CreateFrame("Frame", "DBCat"..i, CategoryLinesFrame)
      x,y = cat:GetSize()
      cat[i]:SetSize(x, 10)
      cat[i]:SetPoint("TOPLEFT", CategoryLinesFrame, "TOPLEFT", 0, -i*12)
      cat[i].text = cat[i]:CreateFontString("DBCatLine"..i, "OVERLAY", "ChatFontNormal");
      cat[i].text:SetPoint("TOPLEFT", cat[i], "TOPLEFT", 0, 0)
      cat[i].text:SetText("Test Cat " .. i)

      line[i] = CreateFrame("Frame", "DBLine"..i, LogLinesFrame)
      x,y = line:GetSize()
      line[i]:SetSize(x, 10)
      cat[i]:SetPoint("TOPLEFT", LogLinesFrame, "TOPLEFT", 0, -i*12)
      line[i].text = line[i]:CreateFontString("DBLineLine"..i, "OVERLAY", "ChatFontNormal");
      line[i].text:SetPoint("TOPLEFT", line[i], "TOPLEFT", 0, 0)
      line[i].text:SetText("Test Line " .. i)
    end
  end,

  reset = function(self)
    db(self.loglevel, "resetting debug module save configuration")
    SteaDEBUG = {}
    SteaDEBUG.log = {}
    SteaDEBUG.on = false
    SteaDEBUG.loglength = 3000
  end,

  show = function(self, show)
    if not DBResizeButton then
      self:buildContent()
    end
    if show or show == nil then
      DBFrame:Show()
    else
      DBFrame:Hide()
    end
  end,

  chatCatSwitch = function(self, chatBool)
    self.chatFlag = chatBool

    if self.chatFlag then
      local cats = "{"
      local first = true
      for k,_ in pairs(self.chatCats) do
        if not first then
          cats = cats .. ", "
        end
        first = false
        cats = cats .. k
      end
       cats = cats .. "}"
      db(self.loglevel, "Debug out to chat is set to ON for categories: ", cats)
    else
      db(self.loglevel, "Debug out to chat is set to OFF - why is this here?")
    end
  end,

  chatCat = function(self, cat)
    ret = false
    if self.category[cat] then
      db(self.loglevel, "Added debug category", cat, "to debug out")
      self.chatCats[cat] = 1
      for k,_ in pairs(self.categoryChildren[cat]) do
        self:chatCat(k)
      end
    else
      db(self.loglevel, "Debug category", cat, "has not been registered")
    end
    return ret
  end,

  printAbove = function(self, above)
    db(self.loglevel, "Logging above", above)
    self.l_printAbove = above
  end,

  printBelow = function(self, below)
    db(self.loglevel, "Printing below", below)
    self.l_printBelow = below
  end,

  logAbove = function(self, above)
    db(self.loglevel, "Logging above", above)
    self.l_logAbove = above
  end,

  logBelow = function(self, below)
    db(self.loglevel, "Logging below", below)
    self.l_logBelow = below
  end,

  registerCategory = function(self, category_in, log)
    local cat = category_in
    local child = nil
    local last = nil

    while not self.category[cat] do
      self.categoryChildren[cat] = {}
      self.category[cat] = 1
      if log == nil or log then
        self.categoryLog[cat] = 1
      end
      db(self.loglevel, "registered debug category:", cat)

      -- sub cats
      child = cat
      doti = cat.find(cat, "%.[^%.]*$") -- last dot

      if doti ~= nil then
        cat = string.sub(cat, 1, doti - 1)
      end

      local parent
      if cat ~= child then
        parent = cat
      end

      -- link parent
      if parent and self.categoryChildren[parent] then
        db(self.loglevel, "added child:", child,"for", parent)
        self.categoryChildren[parent][child] = 1
      end

      -- find children
      -- the parent may be created after the first child
      -- if this is the parent node of a child we created in last loop it won't be linked yet
      if last ~= nil then
        self.categoryChildren[child][last] = 1
        db(self.loglevel, "added child:", last,"for", child)
      end

      last = child
    end
  end,
}

-- global
function db(target, ...)
  if SteaDEBUG and SteaDEBUG.on then
    if SteaDEBUG.log and target and (debug.category[target] or type(target) == "number") then
      local prePrint = nil

      if  type(target) == "number" then
        -- chat
        if target > debug.l_printAbove and target < debug.l_printBelow then
          if debug.chatFlag then
            prePrint = target
          end
        end

        -- logging
        if target > debug.l_logAbove and target < debug.l_logBelow then
          table.insert(SteaDEBUG.log, {target, ...})
        end
      else -- category string
        -- chat
        if #debug.chatCats then
          if debug.chatFlag and debug.chatCats[target] then
            prePrint = target
          end
        else
          if debug.chatFlag then
            prePrint = target
          end
        end

        -- logging
        if debug.categoryLog[target] then
          table.insert(SteaDEBUG.log, {target, ...})
        end
      end

      if prePrint then
        -- just like a regular debug out, but with logging system enabled and category obeying print
        print("|cfff00000" .. addonName .. ": DEBUG [" .. prePrint .. "]|r", ...)
      end
    else
      -- just like a regular debug out
      print("|cfff00000" .. addonName .. ": DEBUG:|r", target, ...)
    end
  end
end

addonData.debug = debug



