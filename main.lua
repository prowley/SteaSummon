-- set things going

-- TODO: silent summon request
-- TODO: add click nag button
-- TODO: add raid instructions
-- TODO: add more clickers nag
-- TODO: add type down search of list
-- TODO: add fancy spell casting next button
-- TODO: send some messages over whisper channel, not broadcast
-- TODO: add sound when next button pops
-- TODO: L10N **** Prio

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

-- colored print to chat window
function cprint(...)
    print("|cf00fffff", addonName, ":|r ", ...)
end

start()
