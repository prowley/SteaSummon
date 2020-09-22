-- user config

local addonName, addonData = ...

-- defaults

local summonWords = {}
summonWords[1] = "123"
summonWords[2] = "123 please"
summonWords[3] = "123 plz"
summonWords[4] = "summon"
summonWords[5] = "summon please"
summonWords[6] = "summon plz"
summonWords[7] = "summon me"
summonWords[8] = "summon me please"
summonWords[9] = "summon me plz"
summonWords[10] ="are summons available?"
summonWords[11] ="are summons available"
summonWords[12] ="are summons avail?"
summonWords[13] ="are summons avail"
summonWords[14] ="are summons ready?"
summonWords[15] ="are summons ready"
summonWords[16] ="summons available?"
summonWords[17] ="summons available"
summonWords[18] ="summons avail?"
summonWords[19] ="summons avail"
summonWords[20] ="summons ready?"
summonWords[21] ="summons ready"

settings = {
  init = function(self)
    if SteaSummonSave == nil or SteaSummonSave.prioplayers == nil then
      self:reset()
    end
  end,

  reset = function(self)
      SteaSummonSave = {}
      SteaSummonSave.summonWords = summonWords
      SteaSummonSave.debug = false
      SteaSummonSave.show = 2
      SteaSummonSave.updates = true
      SteaSummonSave.prioplayers = {[1]="Stea"}
      SteaSummonSave.warlocks = true
      SteaSummonSave.raidchat = "Summoning %p"
      SteaSummonSave.whisperchat = "Summoning you to %l in %z"
      SteaSummonSave.saychat = "Summoning %p, please click the portal"
      SteaSummonSave.experimental = false
  end,

  findSummonWord = function(self, phrase)
    for k,v in pairs(SteaSummonSave.summonWords) do
      if v == phrase then
        return true
      end
    end
    return false
  end,

  findPrioPlayer = function(self, player)
    for k,v in pairs(SteaSummonSave.prioplayers) do
      if v == player then
        return true
      end
    end
    return false
  end,

  debug = function(bug)
    if bug ~= nil then
      SteaSummonSave.debug = bug
    end
    return SteaSummonSave.debug
  end,

  showWindow = function(self)
    return SteaSummonSave.show == 1
  end,

  showActive = function(self)
    return SteaSummonSave.show == 2
  end,

  showJustMe = function(self)
    return SteaSummonSave.show == 3
  end,

  showNever = function(self)
    return SteaSummonSave.show == 4
  end,

  useUpdates = function(self)
    return SteaSummonSave.updates
  end,

  getSettings = function(self)
    return SteaSummonSave
  end,

  getWindowPos = function(self)
      return SteaSummonSave.winowpos
  end,

  setWindowPos = function(self, pos)
      SteaSummonSave.winowpos = pos
  end,

  options_init = function(self)
    self.options.panel = CreateFrame("Frame", "optionsPanel", UIParent );
    self.options.panel.name = "SteaSummon";

    self.options.showsummon = CreateFrame("CheckButton", "oshowsummoncheck", self.options.panel, OptionsCheckButtonTemplate);
    self.options.showsummon:SetPoint("TOPLEFT","optionsPanel","TOPLEFT",5,5)
    self.options.showsummon:SetWidth(80)
    self.options.showsummon:SetHeight(25)
    self.options.showsummon:SetText("Stea")
    self.options.showsummon:Show()

    self.options.panel.setframe = CreateFrame("Frame", "optionsPanelUI", self.options.panel );
    self.options.panel.setframe.name = "optionsUI";
    --self.options.panel.setframe.scroll = CreateFrame("ScrollFrame", "SteaSummonScroll",
    --    options.panel.setframe, "UIPanelScrollFrameTemplate");

    self.options.panel:Show()
    InterfaceOptions_AddCategory(self.options.panel);
  end,
}

addonData.settings = settings
