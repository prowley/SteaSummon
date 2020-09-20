local addonName, addonData = ...

local wordlist = {
  KethoEditBox_Show = function(table, parent)
    if not KethoEditBox then
      local f = CreateFrame("Frame", "KethoEditBox", parent) --, "DialogBoxFrame")
      f:SetPoint("CENTER")
      f:SetSize(300, 250)

      f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
        edgeSize = 16,
        insets = { left = 8, right = 6, top = 8, bottom = 8 },
      })
      f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue

      -- Movable
      f:SetMovable(true)
      f:SetClampedToScreen(true)
      f:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
          self:StartMoving()
        end
      end)
      f:SetScript("OnMouseUp", f.StopMovingOrSizing)

      -- ScrollFrame
      local sf = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame", KethoEditBox, "UIPanelScrollFrameTemplate")
      sf:SetPoint("LEFT", 16, 0)
      sf:SetPoint("RIGHT", -32, 0)
      sf:SetPoint("TOP", 0, -16)
      sf:SetPoint("BOTTOM", KethoEditBoxButton, "TOP", 0, 0)

      -- EditBox
      local eb = CreateFrame("EditBox", "KethoEditBoxEditBox", KethoEditBoxScrollFrame)
      eb:SetSize(sf:GetSize())
      eb:SetMultiLine(true)
      eb:SetAutoFocus(false) -- dont automatically focus
      eb:SetFontObject("ChatFontNormal")
      eb:SetScript("OnEscapePressed", function()
        f:Hide()
      end)
      sf:SetScrollChild(eb)

      -- Resizable
      f:SetResizable(true)
      f:SetMinResize(150, 100)

      local rb = CreateFrame("Button", "KethoEditBoxResizeButton", KethoEditBox)
      rb:SetPoint("BOTTOMRIGHT", -6, 7)
      rb:SetSize(16, 16)

      rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
      rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
      rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

      rb:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
          f:StartSizing("BOTTOMRIGHT")
          self:GetHighlightTexture():Hide() -- more noticeable
        end
      end)
      rb:SetScript("OnMouseUp", function(self, button)
        f:StopMovingOrSizing()
        self:GetHighlightTexture():Show()
        eb:SetWidth(sf:GetWidth())
      end)
      --f:Show()
    end

    if table then
      local text = ""
      for word,v in pairs(addonData.settings.getSummonWords()) do
        text = text .. word .. "\n"
      end
      KethoEditBoxEditBox:SetText(text)
    end
    --KethoEditBox:Show()
    return KethoEditBox
  end
}

addonData.wordlist = wordlist
