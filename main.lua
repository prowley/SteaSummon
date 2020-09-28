-- set things going

-- TODO: add raid/party join wait list propogation (partial, needs work to reduce traffic)
-- TODO: silent summon request
-- TODO: add click nag button
-- TODO: be aware of where the raid is summoning to
-- TODO: notice people who log out while on summon list
-- TODO: detect AFKs and kick them - fast
-- TODO: fix the networking code
-- TODO: prioritize people with world buffs
-- TODO: add raid instructions
-- TODO: add more clickers nag
-- TODO: there appear to be race conditions, seems like events may be executed on another thread
        -- also, doesnt appear blizz compiled in a mutex... which is nice.
-- TODO: add ability to remove yourself from the summon list
-- TODO: add type down search of list
-- TODO: add shard count, and maybe collective count?
-- TODO: add fancy spell casting next button
-- TODO: send some messages over whisper channel, not broadcast

-- notes:
--
-- ritual of summoning icon: ../ICONS/Spell_Shadow_Twilight
-- soul shard icon: ../ICONS/INV_Misc_Gem_Amethyst_02
-- gold ring (minimap frame button): ../COMMON/BlueMenuRing.png
-- gold ring (minimap looks closer): ../COMMON/RingBorder
-- gold ring: ../COMMON/GoldRing
-- indicators (round): ../COMMON/inicator-(Red,Yellow,Gray,Green)
-- button fram UI-Quickslot /-Depress

local addonName, addonData = ...

-- colored print to chat window
function cprint(...)
    print("|cf00fffff", addonName, ":|r ", ...)
end

start()
