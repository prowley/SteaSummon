local _, addonData = ...
local L = LibStub("AceLocale-3.0"):GetLocale("SteaSummon")

local optionsgui = {
  options = {
    type = "group",
    childGroups = "tab",
    args = {
      desc = {
        order = 0,
        image = "Interface/ICONS/Spell_Shadow_Twilight",
        imageCoords = { 0, 1, 0, 1 },
        type = "description",
        name = function()
          local name, _ = UnitName("player")
          local pats = { ["%%name"] = name }
          local s = L["One button summoning, shared summoning list...    (Options for: %name)"]
          return tstring(s, pats)
        end
      },
      --[[general = {
        name = L["General"],
        type = "group",
        order = 0,
        args = {]]
          windheader = {
            order = 0,
            type = "header",
            name = L["Window Options"]
          },
          wnddesc = {
            order = 4,
            type = "description",
            width = "1.5",
            name = L["Change the scale of the interface. Set the window to always show before adjusting scale in order to see the results."]
          },
          enable = {
            order = 6,
            name = L["Show Summon Window"],
            desc = "Toggles the summon window",
            type = "select",
            width = "double",
            descStyle = "inline",
            values = {
              [1] = L["Always"],
              [2] = L["Only when summons are active"],
              [3] = L["Only when I am in the active summon list"],
              [4] = L["Never"]
            },
            set = function(_, val)
              SteaSummonSave.show = val
              addonData.summon:showSummons() -- kick off change in display
            end,
            get = function()
              return SteaSummonSave.show
            end,
          },
          wndshowdesc = {
            order = 7,
            type = "description",
            width = "normal",
            name = L["wnddesc"]
          },
          --[[sumheader = {
            order = 7,
            type = "header",
            name = "Summon Options"
          },]]
          savedesc = {
            order = 10,
            type = "description",
            width = "normal",
            name = L["savedesc"]
          },
          keep = {
            order = 9,
            type = "range",
            name = L["Summon list save time (in minutes)"],
            desc = L["How long to preserve the summon list between logins"],
            min = 0,
            max = 300,
            softMin = 0,
            softMax = 59,
            step = 1,
            bigStep = 1,
            width = "double",
            set = function(_, val)
              SteaSummonSave.waitingKeepTime = val
            end,
            get = function()
              return SteaSummonSave.waitingKeepTime
            end,
          },
          windowSize = {
            order = 2,
            type = "range",
            name = L["Summon window scale"],
            desc = L["wndscale"],
            min = 0.1,
            max = 2,
            softMin = 0.3,
            softMax = 3,
            step = 0.1,
            bigStep = 0.1,
            width = "normal",
            isPercent = true,
            set = function(_, val)
              SteaSummonSave.windowSize = val
              SteaSummonFrame:SetScale(val)
            end,
            get = function()
              return SteaSummonSave.windowSize
            end,
          },
          listSize = {
            order = 3,
            type = "range",
            name = L["Summon list scale"],
            desc = L["sumscale"],
            min = 0.1,
            max = 3,
            softMin = 0.3,
            softMax = 3,
            step = 0.1,
            bigStep = 0.1,
            width = "normal",
            isPercent = true,
            set = function(_, val)
              SteaSummonSave.listSize = val
              SteaSummonButtonFrame:SetScale(val)
            end,
            get = function()
              return SteaSummonSave.listSize
            end,
          },
        --},
      },
    },
  }
--}

local chat = {
  name = L["Messages"],
  type = "group",
  order = 4,
  args = {
    header = {
      order = 8,
      type = "header",
      name = L["Message Options"]
    },
    desc = {
      order = 9,
      type = "description",
      name = L["msgopdesc"]
    },
    raid = {
      order = 10,
      name = L["Summon raid notification text"],
      desc = L["a sentence that posts to raid when someone is summoned"],
      type = "input",
      width = "full",
      set = function(_, val)
        SteaSummonSave.raidchat = val
      end,
      get = function()
        return SteaSummonSave.raidchat
      end
    },
    whisper = {
      order = 11,
      name = L["Summon whisper notification text"],
      desc = L["a sentence that is whispered to the person being summoned"],
      type = "input",
      width = "full",
      set = function(_, val)
        SteaSummonSave.whisperchat = val
      end,
      get = function()
        return SteaSummonSave.whisperchat
      end
    },
    raidinfo = {
      order = 13,
      name = L["Raid summon instructions"],
      desc = L["a sentence that that posts to raid periodically"],
      type = "input",
      width = "double",
      set = function(_, val)
        SteaSummonSave.raidinfo = val
      end,
      get = function()
        return SteaSummonSave.raidinfo
      end
    },
    raidtimer = {
      order = 14,
      type = "range",
      name = L["Raid summon instructions period (minutes)"],
      desc = L["How long to wait between sending to chat"],
      min = 0,
      max = 10,
      step = 1,
      width = "double",
      set = function(_, val)
        SteaSummonSave.raidinfotimer = val
      end,
      get = function()
        return SteaSummonSave.raidinfotimer
      end,
    },
    clickersnag = {
      order = 15,
      name = L["Raid request for clickers"],
      desc = L["a sentence that that posts to raid periodically when there not enough clickers to summon"],
      type = "input",
      width = "double",
      set = function(_, val)
        SteaSummonSave.clickersnag = val
      end,
      get = function()
        return SteaSummonSave.clickersnag
      end
    },
    clickertimer = {
      order = 16,
      type = "range",
      name = L["Raid clicker request period (minutes)"],
      desc = L["How long to wait between sending to chat"],
      min = 0,
      max = 10,
      step = 1,
      width = "double",
      set = function(_, val)
        SteaSummonSave.clickersnagtimer = val
      end,
      get = function()
        return SteaSummonSave.clickersnagtimer
      end,
    },
    clicknag = {
      order = 17,
      name = L["Summoning portal click nag"],
      desc = L["a sentence that posts to say when you click the Next button while casting"],
      type = "input",
      width = "double",
      set = function(_, val)
        SteaSummonSave.clicknag = val
      end,
      get = function()
        return SteaSummonSave.clicknag
      end
    },
    say = {
      order = 12,
      name = L["Summon portal click request in say"],
      desc = L["a sentence that posts to say to request others click on the portal"],
      type = "input",
      width = "full",
      set = function(_, val)
        SteaSummonSave.saychat = val
      end,
      get = function()
        return SteaSummonSave.saychat
      end
    },
  },
}

local summonwords = {
  name = L["Triggers"],
  type = "group",
  order = 5,
  args = {
    header = {
      order = 0,
      type = "header",
      name = L["Trigger Phrases"]
    },
    desc = {
      order = 1,
      type = "description",
      name = L["trigphrasedesc"]
    },
    summonWords = {
      order = -1,
      name = L["Trigger phrases for summon. One per line."],
      desc = L["chat lines that will add a summon request for the raider"],
      type = "input",
      multiline = 23,
      width = "full",
      set = function(_, val)
        SteaSummonSave.summonWords = addonData.util:multiLineToTable(val)
      end,
      get = function()
        return addonData.util:tableToMultiLine(SteaSummonSave.summonWords)
      end
    }
  }
}

local priorities = {
  name = L["Priorities"],
  type = "group",
  order = 6,
  args = {
    header = {
      order = 0,
      type = "header",
      name = L["Priority Options"]
    },
    desc = {
      order = 1,
      type = "description",
      name = L["These options determine where in the summon list players are inserted when they ask for a summon."]
    },
    warlocks = {
      order = 2,
      name = L["Warlocks first"],
      desc = L["Put unbuffed summoners at the top of the list when they request a summon"],
      type = "toggle",
      width = "double",
      descStyle = "inline",
      set = function(_, val)
        SteaSummonSave.warlocks = val
      end,
      get = function()
        return SteaSummonSave.warlocks
      end
    },
    maxWarlocks = {
      order = 3,
      name = L["Maximum warlocks first"],
      desc = L["Maximum summoners to be prioritized"],
      type = "range",
      min = 1,
      max = 5,
      step = 1,
      disabled = function()
        return not SteaSummonSave.warlocks
      end,
      width = "double",
      set = function(_, val)
        SteaSummonSave.maxLocks = val
      end,
      get = function()
        return SteaSummonSave.maxLocks
      end
    },
    buffs = {
      order = 6,
      name = L["Prioritize buffed players"],
      desc = L["Put players with world buffs ahead of named priority players"],
      type = "toggle",
      width = "full",
      descStyle = "inline",
      set = function(_, val)
        SteaSummonSave.buffs = val
      end,
      get = function()
        return SteaSummonSave.buffs
      end
    },
    names = {
      order = 7,
      name = L["Players to summon first, if by first, you mean behind warlocks and buffed players. One player per line."],
      desc = L["These players will move to the front of the summon list when they request a summon"],
      width = "full",
      type = "input",
      multiline = 7,
      set = function(_, val)
        SteaSummonSave.prioplayers = addonData.util:multiLineToTable(addonData.util:case(val, "\n"))
      end,
      get = function()
        return addonData.util:tableToMultiLine(SteaSummonSave.prioplayers)
      end
    },
    last = {
      order = 99,
      name = L["Players to summon last. Some people should just be nicer. One player per line."],
      desc = L["These players will move to the back of the summon list and stay there"],
      width = "full",
      type = "input",
      multiline = 7,
      set = function(_, val)
        SteaSummonSave.shitlist = addonData.util:multiLineToTable(addonData.util:case(val, "\n"))
      end,
      get = function()
        return addonData.util:tableToMultiLine(SteaSummonSave.shitlist)
      end
    }
  },
}

local advanced = {
  name = L["Advanced"],
  type = "group",
  order = -1,
  args = {
    header = {
      order = 0,
      type = "header",
      name = L["Advanced Options"]
    },
    desc = {
      order = 1,
      type = "description",
      name = L["These are options that, should you change them, will blow up your computer."]
    },
    debug = {
      order = 5,
      name = L["Debug"],
      desc = L["Turn on debugging statements"],
      type = "toggle",
      width = "full",
      descStyle = "inline",
      set = function(_, val)
        SteaDEBUG.on = val
      end,
      get = function()
        return SteaDEBUG.on
      end
    },
    experimental = {
      order = 6,
      name = L["Enable Experimental Features"],
      desc = L["This could be anything. It will probably be horribly broken, or worse, not do very much."],
      type = "toggle",
      width = "full",
      descStyle = "inline",
      set = function(_, val)
        SteaSummonSave.experimental = val
      end,
      get = function()
        return SteaSummonSave.experimental
      end
    },
    reset = {
      order = 8,
      name = L["Reset to Defaults"],
      desc = L["Reset all options to the default values"],
      type = "execute",
      func = addonData.settings:reset()
    },
    updates = {
      order = 4,
      name = L["Use AddOn Broadcast Communications"],
      desc = L["broadcastdesc"],
      type = "toggle",
      width = "double",
      descStyle = "inline",
      set = function(_, val)
        SteaSummonSave.updates = val
        addonData.gossip:netOn(val)
      end,
      get = function()
        return SteaSummonSave.updates
      end
    },
    buildheader = {
      order = 10,
      type = "header",
      name = L["Version Details"]
    },

    build = {
      order = 11,
      type = "description",
      name = function()
        local version, build, date, tocversion = GetBuildInfo()
        local pat = { ["%%v"] = version, ["%%b"] = build, ["%%d"] = date, ["%%t"] = tocversion, ["%%s"] = GetAddOnMetadata("SteaSummon", "Version") }
        local s = L["SteaSummon version %s\n\nWoW client\nversion: %v\nbuild: %b\ndate: %d\ntocversion: %t"]
        return tstring(s, pat)
      end
    },
    --[[bags = {
      order = -1,
      name = "bags",
      desc = "bags",
      type = "input",
      multiline = 23,
      width = "full",
      set = function(_, val)

      end,
      get = function()
        return rummage()
      end
    }]]
  },
}

--- rummage for food and drink
function rummage()
  out = ""
  local icon, itemCount, locked, quality, readable, lootable,
        isFiltered, noValue, itemID
  local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
        itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID,
        isCraftingReagent
  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      icon, itemCount, locked, quality, readable, lootable,
        itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot)
      if itemID then
        itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
        itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID,
        isCraftingReagent = GetItemInfo(itemID)
        out = out .. itemName .. " " .. itemID .. " " ..  itemType .. " " .. itemSubType .. " " .. itemClassID
            .. " " .. itemSubClassID .. " " .. itemIcon .. "\n"
      end
    end
  end
  return out
end

function optionsgui.init()
  LibStub("AceConfig-3.0"):RegisterOptionsTable("SteaSummon", optionsgui.options, "ss")
  LibStub("AceConfig-3.0"):RegisterOptionsTable("SteaSummonMessages", chat, "sschat")
  LibStub("AceConfig-3.0"):RegisterOptionsTable("SteaSummonWords", summonwords, "sswords")
  LibStub("AceConfig-3.0"):RegisterOptionsTable("SteaSummonPrios", priorities, "ssprio")
  LibStub("AceConfig-3.0"):RegisterOptionsTable("SteaSummonAdv", advanced)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SteaSummon")
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SteaSummonMessages", L["Messages"], "SteaSummon")
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SteaSummonWords", L["Triggers"], "SteaSummon")
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SteaSummonPrios", L["Priorities"], "SteaSummon")
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SteaSummonAdv", L["Advanced"], "SteaSummon")
end



addonData.optionsgui = optionsgui