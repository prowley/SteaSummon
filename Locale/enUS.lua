--localization file for english/United States
local L = LibStub("AceLocale-3.0"):NewLocale("SteaSummon", "enUS", true)


L["Language"] = true

--- main.lua
L["Summon Next"] = true
L["Set Destination"] = true

--- chat.lua
L["list"] = true
L["%name waiting: %number seconds"] = true
L["Summon waiting list"] = true
L["%count waiting"] = true
L["debug"] = true
L["on"] = true
L["off"] = true
L["add"] = true

--- raid.lua
L["Warlocks"] = true
L["Clickers"] = true

--- settings.lua
L["Summoning %p"] = true
L["Summoning you to %l in %z"] = true
L["Summoning %p, please click the portal"] = true
L["raidinfo"] = "Summons are available. Type %t for summons, -%t to cancel, %t to reset to requested on summon failure"
L["clickersnag"] = "Need more clickers at %l, %z"
L["clicknag"] = "Click the summoning portal!"
L["You are in the summon queue. Whisper me an alt name if you don't want to wait online."] = true
L["You are near the top of the summon queue. Get online now."] = true

--- summon.lua
L["Warlock"] = true
L["W"] = true
L["requested"] = true
L["Buffed"] = true
L["B"] = true
L["Prioritized"] = true
L["P"] = true
L["Last"] = true
L["L"] = true
L["Normal"] = true
L["N"] = true
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
L["Alt:"] = true
L["Request"] = true
L["Reset"] = true
L["accepted"] = true
L["declined"] = true

--- optionsgui.lua
L["One button summoning, shared summoning list...    (Options for: %name)"] = true

-- window

L["Help"] = true
L["plushelp"] = "Use this button to open the options tree below the main SteaSummon entry. There are many options."
  .. " Take some time to go over the options in each section and set them as you like them. All options are per "
  .. "character.\n\n"
L["summonhelp"] = "The summon button will summon the next player with the 'requested' status. When summoning a player"
  .. " the status changes to 'pending', and all players with SteaSummon can see the change in status. "
  .. "Other warlocks with SteaSummon will automatically summon the next player after the one you are summoning."
  .. " This button only appears for warlocks who are level 20 or higher, and when there are remaining people"
  .. " in the list to summon.\n\nYou can set a key bind for this button in the main key bindings menu, under the "
  .. "Addons category.\n\n"
L["desthelp"] = "The destination for summons is set when you start to summon. It is also set when you click "
  .. "the raid information button, and when you explicitly set it in the context menu. Everyone "
  .. "in your raid with SteaSummon can see the destination.\n\nWhen a destination is set only warlocks at the "
  .. "destination can manage the summon list, and only raiders at the destination will detect people nearby who "
  .. "are on the summon list. Raiders can always manage their own entry in the summon list.\n\n"
  .. "In addition to the list management restrictions, when a destination is set the number of warlocks, and the"
  .. " number of people available to click portals, at the destination is shown to everyone with SteaSummon.\n\n"
L["raidinfohelp"] = "The raid information button controls the periodic raid messages and it only displays for warlocks"
  .. " who are level 20 or higher.\n\nThe first of the messages requests for more people to get to the destination "
  .. "so that summoning can begin. This message triggers when there are less than 3 people or"
  .. " there is no warlock at the destination.\n\nThe second message informs the raid that summons are available"
  .. " and gives brief instructions for how to request, cancel, and refresh individual summons. This message "
  .. "triggers when there are at least 3 people at the destination, and one of them is a warlock of level 20 or higher"
  .. "\n\nYou can set a key bind for this button in the main key bindings menu, under the Addons category.\n\n"


-- display
L["Display"] = true
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
L["Show minimap button"] = true
L["Toggle whether to show the minimap button"] = true

-- messages
L["Messages"] = true
L["Message Options"] = true
L["msgopdesc"] = "These message options may include variable placeholders, prefixed by the % symbol, where dynamic text will be inserted. Blank lines disable the feature.\n\nThe variable options are:\n\n%p : player name\n%l : summon location\n%z : summon zone\n%t : the first trigger phrase"
L["Summon raid notification text"] = true
L["a sentence that posts to raid when someone is summoned"] = true
L["Summon whisper notification text"] = true
L["a sentence that is whispered to the person being summoned"] = true
L["Summon portal click request in say"] = true
L["a sentence that posts to say to request others click on the portal"] = true
L["Raid summon instructions"] = true
L["a sentence that that posts to raid periodically"] = true
L["Raid request for clickers"] = true
L["a sentence that that posts to raid periodically when there not enough clickers to summon"] = true
L["Summoning portal click nag"] = true
L["a sentence that posts to say when you click the Next button while casting"] = true
L["Raid summon instructions period (minutes)"] = true
L["How long to wait between sending to chat"] = true
L["Raid clicker request period (minutes)"] = true
L["Say clicker request period (seconds)"] = true

-- triggers
L["Trigger Phrases"] = true
L["Triggers"] = true
L["trigphrasedesc"] = "Trigger phrases are phrases that people can type into raid or party chat in order to get added to the summon list. Players can also type '-' (minus) and then a trigger phrase to be removed from the list."
L["Trigger phrases for summon. One per line."] = true
L["chat lines that will add a summon request for the raider"] = true

-- priorities
L["Priorities"] = true
L["Priority Options"] = true
L["Maximum warlocks first"] = true
L["Maximum summoners to be prioritized"] = true
L["These options determine where in the summon list players are inserted when they ask for a summon."] = true
L["Warlocks first"] = true
L["Put unbuffed summoners at the top of the list when they request a summon"] = true
L["Prioritize buffed players"] = true
L["Put players with world buffs ahead of named priority players"] = true
L["Players to summon first, if by first, you mean behind warlocks and buffed players. One player per line."] = true
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
L["SteaSummon version %s\n\nWoW client\nversion: %v\nbuild: %b\ndate: %d\ntocversion: %t"] = true

-- alts
L["Alt Support"] = true
L["Alt Character Options"] = true
L["altdesc"] = "These options allow players to log on another character while waiting for their summon to be ready."
L["Enable only when player buffed"] = true
L["altbuffeddesc"] = "Alt support only triggers the instructional whisper when the player is buffed (all players can still use alt support)"
L["Enable only when the queue spot reaches"] = true
L["qspotdesc"] = "Alt support only triggers the instructional whisper when the player is at or lower in the queue than this value"
L["Whisper alts when they reach this queue spot"] = true
L["Automatically register your characters for alt support"] = true
L["These are the characters you might be on when your summon is ready"] = true
L["qspotreadydesc"] = "Alt support only triggers ready whisper when the player reaches this spot in the queue"
L["When out of online players to summon, whisper this many extra alts"] = true
L["qspotboostreadydesc"] = "Raise players from their alts to keep summons going"
L["Whisper instructional text"] = true
L["a sentence that is whispered to instruct the player how to add an alt for their summon"] = true
L["Whisper summon ready text"] = true
L["a sentence that is whispered to tell an alt their summon is ready"] = true

-- raid
L["Raid Management"] = true
L["Raid Management Options"] = true
L["These options perform raid management actions to form your raid when you are raid leader."] = true
L["Warlocks get assist"] = true
L["Give assist status to unbuffed summoners"] = true
L["Final raid leadership are named players"] = true
L["When relinquishing leadership, ensure only the named players keep their roles"] = true
L["Delay leadership transfer"] = true
L["Only transfer leadership once the destination is unset and summons are over"] = true
L["Players to give assist"] = true
L["These players will be given raid assist when they join the raid"] = true
L["Players to promote to leader"] = true
L["leaderdesc"] = "These players will be given assist and then (in preference order) promoted to leader when leadership is relinquished"
L["Players to set as master looter"] = true
L["mldesc"] = "These players will be given assist and then assigned master looter (in preference order) when leadership is relinquished"
L["Auto invite players who whisper these trigger words"] = true
L["These trigger words will trigger an invitation to the raid"] = true
L["Enable auto invite"] = true
L["Allow people to request invites to the raid via whisper"] = true
L["Only Guild"] = true
L["Only Guild and Friends"] = true
L["Anyone"] = true
L["Off"] = true
L["Enable accept invites"] = true
L["Accept group invites to the raid"] = true
L["Auto convert to raid"] = true
L["When you form a party, convert it to a raid"] = true
L["Automatic Invite Options"] = true
L["These options determine how automatic invite and accept works"] = true

--- gossip.lua
L["There is a newer version available."] = true
L["version"] = "Network communications is disabled. Your version of SteaSummon has an old network protocol version. You should update and restart your client now."

-- minimap.lua
L["SteaSummon Options"] = true
L["Show/Hide Minimap Button"] = true
L["Configuration"] = true
L["Show/Hide Summon Window"] = true
L["Key Bindings"] = true
L["SteaSummon"] = true
L["Options"] = true
L["Toggle Raid Information"] = true
L["Set/Unset Destination"] = true
L["Request Summon"] = true
L["Reset Summon"] = true
L["Cancel Summon"] = true
L["Relinquish Raid Lead"] = true
L["Clear Summon List"] = true
L["clearlistdesc"] = "Performing this action will clear the list for everyone else in the raid. You could just hide the window. Are you sure you want to continue?"
L["Manage List"] = true
L["Request/Reset Summon"] = true
