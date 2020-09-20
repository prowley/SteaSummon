-- set things going

-- TODO: add raid/party join wait list propogation (partial, needs work to reduce traffic)
-- TODO: silent summon request
-- TODO: add click nag button
-- TODO: be aware of where the raid is summoning to
-- TODO: notice people who log out while on summon list

local addonName, addonData = ...

-- for debugging
function db(...)
  if SteaSummonSave and SteaSummonSave.debug then
    print("|cf00fffff", addonName, ": DEBUG:|r ", ...)
  end
end

-- colored print to chat window
function cprint(...)
    print("|cf00fffff", addonName, ":|r ", ...)
end

start()
