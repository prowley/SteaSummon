-- set things going

-- TODO: add type down search of list
-- TODO: add sound when next button pops
-- TODO: party/raid confirmation of add
-- TODO: location based summon phrases, channels

--- Visual
-- TODO: add fancy spell casting next button
-- TODO: alts on tooltip for offline
-- TODO: buffs displayed in tooltip? over priority reason
-- TODO: indication when raid lead, click to pass lead
-- TODO: indication when net lead, also see other addon users
-- TODO: button for requesting summon

-- notes:
--
-- ritual of summoning icon: Interface/ICONS/Spell_Shadow_Twilight
-- soul shard icon: Interface/ICONS/INV_Misc_Gem_Amethyst_02
-- gold ring (minimap frame button): Interface/COMMON/BlueMenuRing.png
-- gold ring (minimap looks closer): Interface/COMMON/RingBorder
-- gold ring: Interface/COMMON/GoldRing
-- indicators (round): Interface/COMMON/indicator-(Red,Yellow,Gray,Green)
-- button fram UI-Quickslot /-Depress
-- sound: RAID_WARNING = 8959,

local addonName, addonData = ...
local L = LibStub("AceLocale-3.0"):GetLocale("SteaSummon")

-- keybind stuff
BINDING_HEADER_STEASUMMON = "SteaSummon"
_G["BINDING_NAME_CLICK SteaSummonButton38:LeftButton"] = L["Summon Next"]
_G["BINDING_NAME_CLICK SteaSummonToButton:LeftButton"] = L["Set Destination"]

local SteaSummon = {}

-- colored print to chat window
function cprint(...)
    print("|cf00fffff" .. addonName .. ":|r ", ...)
end

function tstring(str, patterns)
    for key, val in pairs(patterns) do
        str = string.gsub(str, key, val)
    end

    return str
end

addonData.main = SteaSummon
addonData.start()
