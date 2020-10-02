local _, addonData = ...


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
          return "One button summoning, shared summoning list... (Options for: " .. name .. ")"
        end
      },
      general = {
        name = "General",
        type = "group",
        order = 0,
        args = {
          windheader = {
            order = 0,
            type = "header",
            name = "Window Options"
          },
          wnddesc = {
            order = 4,
            type = "description",
            width = "normal",
            name = "Change the scale of the interface. Set the window to always show before adjusting scale in order to see the results."
          },
          enable = {
            order = 6,
            name = "Show Summon Window",
            desc = "Toggles the summon window",
            type = "select",
            width = "double",
            descStyle = "inline",
            values = {
              [1] = "Always",
              [2] = "Only when summons are active",
              [3] = "Only when I am in the active summon list",
              [4] = "Never"
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
            name = "Change when to display interface. Always, when there is someone waiting to be summoned, when you are in the summon list, or never"
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
            name = "If you are in a group when you log back in within this time, your summon list is preserved. "
              .. "This saves the list if all addons users in the group log out."
          },
          keep = {
            order = 9,
            type = "range",
            name = "Summon list save time (in minutes)",
            desc = "How long to preserve the summon list between logins",
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
            name = "Summon window scale",
            desc = "Changes the scale of the window. It helps to have show always set to see the effect while setting.",
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
            name = "Summon list scale",
            desc = "Changes the scale of the window contents. It helps to have show always set to see the effect while setting.",
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
        name = "Messages",
        type = "group",
        order = 4,
        args = {
          header = {
            order = 8,
            type = "header",
            name = "Message Options"
          },
          desc = {
            order = 9,
            type = "description",
            name = "These message options may include variable placeholders, prefixed by the % symbol, where dynamic text will be inserted. Blank lines disable the feature.\n\nThe variable options are:\n\n%p : player name\n%l : summon location\n%z : summon zone"
          },
          raid = {
            order = 10,
            name = "Summon raid notification text",
            desc = "a line that posts to raid when someone is summoned",
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
            name = "Summon whisper notification text",
            desc = "a line that is whipered to the person being summoned",
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
            name = "Summon portal click request in say",
            desc = "a line that posts to say when someone is summoned",
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
            name = "Trigger Phrases"
          },
          desc = {
            order = 1,
            type = "description",
            name = "Trigger phrases are phrases that people can type into raid or party chat in order to get added to the summon list. Players can also type '-' (minus) and then a trigger phrase to be removed from the list."
          },
          summonWords = {
            order = -1,
            name = "Trigger phrases for summon. One per line.",
            desc = "chat lines that will add a summon request for the raider",
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
        name = "Priorities",
        type = "group",
        order = 6,
        args = {
          header = {
            order = 0,
            type = "header",
            name = "Priority Options"
          },
          desc = {
            order = 1,
            type = "description",
            name = "These options determine where in the summon list players are inserted when they ask for a summon."
          },
          warlocks = {
            order = 2,
            name = "Warlocks first",
            desc = "Put summoners at the top of the list when they request a summon",
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
            name = "Prioritize buffed players",
            desc = "Put players with world buffs ahead of named priority players",
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
            name = "Players to summon first, if by first, you mean behind warlocks. One player per line.",
            desc = "These players will move to the front of the summon list when they request a summon",
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
            name = "Players to summon last. Some people should just be nicer. One player per line.",
            desc = "These players will move to the back of the summon list and stay there",
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
         name = "Advanced",
         type = "group",
         order = -1,
         args = {
           header = {
             order = 0,
             type = "header",
             name = "Advanced Options"
           },
           desc = {
             order = 1,
             type = "description",
             name = "These are options that, should you change them, will blow up your computer."
           },
           debug = {
             order = 5,
             name = "Debug",
             desc = "Turn on debugging statements",
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
             name = "Enable Experimental Features",
             desc = "This could be anything. It will probably be horribly broken, or worse, not do very much.",
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
             name = "Reset to Defaults",
             desc = "Reset all options to the default values",
             type = "execute",
             func = addonData.settings:reset()
           },
           updates = {
             order = 4,
             name = "Use AddOn Broadcast Communications",
             desc = "Get and send summoning status updates. Gives you notifications of summon status changes, and helps to keep the summoning list alive through relogs. Makes the Next button more effective with multiple warlock summoners i.e. please don't turn this off.",
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
             name = "Version Details"
           },
           build = {
             order = 11,
             type = "description",
             name = function()
               local version, build, date, tocversion = GetBuildInfo()
               return "version: " .. version .. "\nbuild: " .. build .. "\ndate: " .. date .. "\ntocversion: " .. tocversion .. "\n\nSteaSummon v" .. GetAddOnMetadata("SteaSummon", "Version")
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