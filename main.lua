-- set things going

-- TODO: add click nag button
-- TODO: add raid instructions
-- TODO: add more clickers nag
-- TODO: add type down search of list
-- TODO: add fancy spell casting next button
-- TODO: add sound when next button pops
-- TODO: L10N **** Prio
-- TODO: key bindings

-- notes:
--
-- ritual of summoning icon: ../ICONS/Spell_Shadow_Twilight
-- soul shard icon: ../ICONS/INV_Misc_Gem_Amethyst_02
-- gold ring (minimap frame button): ../COMMON/BlueMenuRing.png
-- gold ring (minimap looks closer): ../COMMON/RingBorder
-- gold ring: ../COMMON/GoldRing
-- indicators (round): ../COMMON/inicator-(Red,Yellow,Gray,Green)
-- button fram UI-Quickslot /-Depress
-- sound: RAID_WARNING = 8959,

local addonName, addonData = ...
local L = LibStub("AceLocale-3.0"):GetLocale("SteaSummon")

-- keybind stuff
BINDING_HEADER_STEASUMMON = "SteaSummon"
_G["BINDING_NAME_CLICK SteaSummonButton38:LeftButton"] = L["Summon Next"]
_G["BINDING_NAME_CLICK SummonToButton:LeftButton"] = L["Set Destination"]

SteaSummon = {}

function SteaSummon:ClickNext()
    addonData.summon:ClickNext()
end

function SteaSummon:ClickSetDestination()
    addonData.summon:ClickSetDestination()
end

-- colored print to chat window
function cprint(...)
    print("|cf00fffff", addonName, ":|r ", ...)
end

function tstring(str, patterns)
    for key, val in pairs(patterns) do
        str = string.gsub(str, key, val)
    end

    return str
end

start()
