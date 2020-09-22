local addonName, addonData = ...


tmpchanges = {}

optionsgui = {
  options = {
    type = "group",
    childGroups = "tab",
    args = {
      desc = {
        order = 0,
        type = "description",
        name = "One button summoning, shared summoning list..."
      },
      general = {
        name = "General",
        type = "group",
        order = 0,
        args = {
          enable = {
            order = 1,
            name = "Show Summon Window",
            desc = "Toggles the summon window",
            type = "select",
            width = "normal",
            descStyle = "inline",
            values = {
               [1] = "Always",
               [2] = "Only when summons are active",
               [3] = "Only when I am in the active summon list",
               [4] = "Never"
            },
            set = function(info, val)
              SteaSummonSave.show = val
              addonData.summon:showSummons() -- kick off change in display
            end,
            get = function(info)
              return SteaSummonSave.show
            end,
          },
          windowSize = {
            order = 2,
            type = "range",
            name = "Summon window size",
            desc = "Changes the size of the window. It helps to have show always set to see the effect while setting.",
            min = 0.1,
            max = 2,
            softMin = 0.3,
            softMax = 3,
            step = 0.1,
            bigStep = 0.1,
            set = function(info, val)
              SteaSummonSave.windowSize = val
              SummonFrame:SetScale(val)
            end,
            get = function(info)
              return SteaSummonSave.windowSize
            end,
          },
          listSize = {
            order = 3,
            type = "range",
            name = "Summon list size",
            desc = "Changes the size of the window contents. It helps to have show always set to see the effect while setting.",
            min = 0.1,
            max = 3,
            softMin = 0.3,
            softMax = 3,
            step = 0.1,
            bigStep = 0.1,
            set = function(info, val)
              SteaSummonSave.listSize = val
              ScrollFrame:SetScale(val)
              ButtonFrame:SetScale(val * 3)
            end,
            get = function(info)
              return SteaSummonSave.listSize
            end,
          },
          header = {
            order = 8,
            type = "header",
            name = "Chat Options"
          },
          desc = {
            order = 9,
            type = "description",
            name = "The following chat options may include variable placeholders, prefixed by the % symbol, where dynamic text will be inserted. Blank lines disable the feature.\n\nThe variable options are:\n\n%p : player name\n%l : summon location\n%z : summon zone"
          },
          raid = {
            order = 10,
            name = "Summon raid notification text",
            desc = "a line that posts to raid when someone in summoned",
            type = "input",
            width = "full",
            set = function(info, val)
              SteaSummonSave.raidchat = val
            end,
            get = function(info)
              return SteaSummonSave.raidchat
            end
          },
          whisper = {
            order = 11,
            name = "Summon whisper notification text",
            desc = "a line that posts to raid when someone in summoned",
            type = "input",
            width = "full",
            set = function(info, val)
              SteaSummonSave.whisperchat = val
            end,
            get = function(info)
              return SteaSummonSave.whisperchat
            end
          },
          say = {
            order = 12,
            name = "Summon portal click request in say",
            desc = "a line that posts to raid when someone in summoned",
            type = "input",
            width = "full",
            set = function(info, val)
              SteaSummonSave.saychat = val
            end,
            get = function(info)
              return SteaSummonSave.saychat
            end
          }
        }
      },
      summonwords = {
        name = "Triggers",
        type = "group",
        order = 1,
        args = {
          summonWords = {
            name = "Trigger phrases for summon. One per line.",
            desc = "chat lines that will add a summon request for the raider",
            type = "input",
            multiline = 25,
            width = "full",
            set = function(info, val)
              SteaSummonSave.summonWords = addonData.util:multiLineToTable(val)
            end,
            get = function(info)
              return addonData.util:tableToMultiLine(SteaSummonSave.summonWords)
            end
          }
        }
      },
      priorities = {
        name = "Priorities",
        type = "group",
        order = 2,
        args = {
          warlocks = {
            order = 0,
            name = "Warlocks first",
            desc = "Put summoners at the top of the list when they request a summon",
            type = "toggle",
            width = "full",
            descStyle = "inline",
            set = function(info, val)
              SteaSummonSave.warlocks = val
            end,
            get = function(info)
              return SteaSummonSave.warlocks
            end
          },
          names = {
            order = 1,
            name = "Players to summon first, if by first, you mean behind warlocks. One player per line.",
            desc = "These players will move to the front of the summon list when they request a summon",
            width = "full",
            type = "input",
            multiline = 8,
            set = function(info, val)
              SteaSummonSave.prioplayers = addonData.util:multiLineToTable(addonData.util:case(val, "\n"))
            end,
            get = function(info)
              return addonData.util:tableToMultiLine(SteaSummonSave.prioplayers)
            end
          },
          last = {
            order = 2,
            name = "Players to summon last. Some people should just be nicer. One player per line.",
            desc = "These players will move to the back of the summon list and stay there",
            width = "full",
            type = "input",
            multiline = 8,
            set = function(info, val)
              SteaSummonSave.shitlist = addonData.util:multiLineToTable(addonData.util:case(val, "\n"))
            end,
            get = function(info)
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
           debug = {
             order = 1,
             name = "Debug",
             desc = "Turn on debugging statements",
             type = "toggle",
             width = "full",
             descStyle = "inline",
             set = function(info, val)
               SteaSummonSave.debug = val
             end,
             get = function(info)
               return SteaSummonSave.debug
             end
           },
           experimental = {
             order = 1,
             name = "Enable Experimental Features",
             desc = "This could be anything. It will probably be horribly broken, or worse, not do very much.",
             type = "toggle",
             width = "full",
             descStyle = "inline",
             set = function(info, val)
               SteaSummonSave.experimental = val
             end,
             get = function(info)
               return SteaSummonSave.experimental
             end
           },
           reset = {
             order = -1,
             name = "Reset to Defaults",
             desc = "Reset all options to the default values",
             type = "execute",
             func = addonData.settings:reset()
           },
           updates = {
             order = 0,
             name = "Use AddOn Broadcast Communications",
             desc = "Get and send summoning status updates. Gives you notifications of summon status changes, and helps to keep the summoning list alive through relogs. Makes the Next button more effective with multiple warlock summoners i.e. please don't turn this off.",
             type = "toggle",
             width = "double",
             descStyle = "inline",
             set = function(info, val)
               SteaSummonSave.updates = val
             end,
             get = function(info)
               return SteaSummonSave.updates
             end
          },
         }
      }
    },
  },

  init = function(self)
    tmpchanges = {
      show = SteaSummonSave.show
    }
    LibStub("AceConfig-3.0"):RegisterOptionsTable("SteaSummon", self.options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SteaSummon")
  end,
}

addonData.optionsgui = optionsgui