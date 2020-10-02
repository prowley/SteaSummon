--localization file for english/United States
local L = LibStub("AceLocale-3.0"):NewLocale("SteaSummon", "enUS", true)

-- main.lua
L["Summon Next"] = true
L["Set Destination"] = true

-- chat.lua
L["list"] = true
L["%name waiting: %number seconds"] = true
L["Summon waiting list"] = true
L["%count waiting"] = true
L["debug"] = true
L["on"] = true
L["off"] = true
L["add"] = true

-- raid.lua
L["Warlocks"] = true
L["Clickers"] = true

-- settings.lua
L["Summoning %p"] = true
L["Summoning you to %l in %z"] = true
L["Summoning %p, please click the portal"] = true

-- summon.lua
L["Warlock"] = true
L["requested"] = true
L["Buffed"] = true
L["Prioritized"] = true
L["Last"] = true
L["Normal"] = true
L["dead"] = true
L["offline"] = true
L["pending"] = true
L["Imagine not having enough mana."] = "Imagine not having enough mana. Now imagine whispering that to yourself when you don't have enough mana."
L["Reason for list placement"] = true
L["[W]arlock, [B]uffs, [P]riority, [N]ormal, [L]ast"] = true
L["summoned"] = true
L["Location: %subzone, %zone"] = true
L["Destination: %subzone, %zone"] = true
L["Next"] = true

-- optionsgui.lua
L["One button summoning, shared summoning list...    (Options for: %name)"] = true
L["General"] = true
L["Window Options"] = true
L["Change the scale of the interface. Set the window to always show before adjusting scale in order to see the results."] = true
L["Show Summon Window"] = true
L["Always"] = true
L["Only when summons are active"] = true
L["Only when I am in the active summon list"] = true
L["Never"] = true
L["wnddesc"] = "Change when to display interface. Always, when there is someone waiting to be summoned, "
              .. "when you are in the summon list, or never"
L["savedesc"] = "If you are in a group when you log back in within this time, your summon list is preserved. "
              .. "This saves the list if all addons users in the group log out."
L["Summon list save time (in minutes)"] = true
L["How long to preserve the summon list between logins"] = true
L["Summon window scale"] = true
L["wndscale"] = "Changes the scale of the window. It helps to have show always set to see the effect while setting."
L["Summon list scale"] = true
L["sumscale"] = "Changes the scale of the window contents. It helps to have show always set to see the effect while setting."
L["Messages"] = true
L["Message Options"] = true
L["msgopdesc"] = "These message options may include variable placeholders, prefixed by the % symbol, where dynamic text will be inserted. Blank lines disable the feature.\n\nThe variable options are:\n\n%p : player name\n%l : summon location\n%z : summon zone"
L["Summon raid notification text"] = true
L["a sentence that posts to raid when someone is summoned"] = true
L["Summon whisper notification text"] = true
L["a sentence that is whispered to the person being summoned"] = true
L["Summon portal click request in say"] = true
L["a sentence that posts to say to request others click on the portal"] = true
L["Trigger Phrases"] = true
L["trigphrasedesc"] = "Trigger phrases are phrases that people can type into raid or party chat in order to get added to the summon list. Players can also type '-' (minus) and then a trigger phrase to be removed from the list."
L["Trigger phrases for summon. One per line."] = true
L["chat lines that will add a summon request for the raider"] = true
L["Priorities"] = true
L["Priority Options"] = true
L["These options determine where in the summon list players are inserted when they ask for a summon."] = true
L["Warlocks first"] = true
L["Put summoners at the top of the list when they request a summon"] = true
L["Prioritize buffed players"] = true
L["Put players with world buffs ahead of named priority players"] = true
L["Players to summon first, if by first, you mean behind warlocks. One player per line."] = true
L["These players will move to the front of the summon list when they request a summon"] = true
L["Players to summon last. Some people should just be nicer. One player per line."] = true
L["These players will move to the back of the summon list and stay there"] = true
L["Advanced"] = true
L["Advanced Options"] = true
L["These are options that, should you change them, will blow up your computer."] = true
L["Debug"] = true
L["Turn on debugging statements"] = true
L["Enable Experimental Features"] = true
L["This could be anything. It will probably be horribly broken, or worse, not do very much."] = true
L["Reset to Defaults"] = true
L["Reset all options to the default values"] = true
L["Use AddOn Broadcast Communications"] = true
L["broadcastdesc"] = "Get and send summoning status updates. Gives you notifications of summon status changes, and helps to keep the summoning list alive through relogs. Makes the Next button more effective with multiple warlock summoners i.e. please don't turn this off."
L["Version Details"] = true
L["version: %v\nbuild: %b\ndate: %d\ntocversion: %t\n\nSteaSummon version %s"] = true