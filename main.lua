-- set things going

-- TODO: add raid/party join wait list propogation (partial, needs work to reduce traffic)
-- TODO: silent summon request
-- TODO: add click nag button
-- TODO: be aware of where the raid is summoning to
-- TODO: notice people who log out while on summon list

-- TODO: fix the cast cancel / pending immediatley
-- TODO: detect AFKs and kick them - fast
-- TODO: fix the networking code
-- TODO: prioritize people with world buffs
-- TODO: add raid instructions
-- TODO: add more clickers nag

local addonName, addonData = ...

-- colored print to chat window
function cprint(...)
    print("|cf00fffff", addonName, ":|r ", ...)
end

start()
