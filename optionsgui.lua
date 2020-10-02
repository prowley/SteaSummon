local _, addonData = ...
local L = LibStub("AceLocale-3.0"):GetLocale("SteaSummon")

tmpchanges = {}

optionsgui = {
  options = {
    type = "group",
    childGroups = "tab",
    args = {
      desc = {
        order = 0,
        image = "Interface/ICONS/Spell_Shadow_Twilight",
        imageCoords = {0,1,0,1},
        type = "description",
        name = function()
          local name, _ = UnitName("player")
          local pats = {["%%name"] = name}
          local s = L["One button summoning, shared summoning list...    (Options for: %name)"]
          return tstring(s, pats)
        end
      },
      general = {
        name = L["General"],
        type = "group",
        order = 0,
        args = {
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
            set = function(_, val)
              SteaSummonSave.windowSize = val
              SummonFrame:SetScale(val)
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
            set = function(_, val)
              SteaSummonSave.listSize = val
              ButtonFrame:SetScale(val)
            end,
            get = function()
              return SteaSummonSave.listSize
            end,
          },
        },
      },
      chat = {
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
          }
        }
      },
      summonwords = {
        name = "Triggers",
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
      },
      priorities = {
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
            desc = L["Put summoners at the top of the list when they request a summon"],
            type = "toggle",
            width = "full",
            descStyle = "inline",
            set = function(_, val)
              SteaSummonSave.warlocks = val
            end,
            get = function()
              return SteaSummonSave.warlocks
            end
          },
          buffs = {
            order = 3,
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
            order = 6,
            name = L["Players to summon first, if by first, you mean behind warlocks. One player per line."],
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
            order = 8,
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
      },
      advanced = {
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
               local pat = {["%%v"]=version, ["%%b"]=build, ["%%d"]=date, ["%%t"]=tocversion, ["%%s"]=GetAddOnMetadata("SteaSummon", "Version")}
               local s = L["version: %v\nbuild: %b\ndate: %d\ntocversion: %t\n\nSteaSummon version %s"]
               return tstring(s, pat)
             end
           },
         }
      }
    },
  },

  init = function(self)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("SteaSummon", self.options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SteaSummon")
  end,
}

addonData.optionsgui = optionsgui