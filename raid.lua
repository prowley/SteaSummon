-- Raid tracking
local addonName, addonData = ...

-- events of interest
-- GROUP_ROSTER_UPDATE
-- RAID_ROSTER_UPDATE
-- PARTY_LEADER_CHANGED
-- NAME_PLATE_UNIT_REMOVED
-- NAME_PLATE_UNIT_ADDED

--GetRaidRosterInfo(1..40)
--UnitInRaid("unit")

local old, new = {}, {}
local inzone = {}

local raid = {
  init = function(self)
    addonData.debug:registerCategory("raid.event")
  end,

  callback = function(self, event, ...)
    db("raid.event", event, ...)

    if addonData.summon.numwaiting == 0 then
      -- let's only do this stuff when there can be an impact
      -- it's a lot of fluff for every two to three seconds anyway
      --return
    end
    -- for now, this is in observe mode until I understand how this event works
    -- it could drive addon network leader election cycle, keep track of close online players etc.
    if (event == "RAID_ROSTER_UPDATE") then
      old, new = new, old
      wipe(new)
      wipe(inzone)
      for i = 1, GetNumGroupMembers() do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, loot = GetRaidRosterInfo(i)
        new[name] = online or false

        if zone == GetZoneText() then
          inzone[name] = true
        else
          inzone[name] = nil
        end

        if isDead then
          db("raid", name, " is dead.")
          addonData.summon:dead(name, true)
        else
          addonData.summon:dead(name, false)
        end
        if old[name] == nil then
          db("raid", name, " joined the raid.")
        elseif old[name] and not online then
          db("raid", name, " has gone offline.")
          addonData.summon:offline(name, true)
        elseif online and not old[name] then
          db("raid", name, " logged back on.")
          addonData.summon:offline(name, false)
        end

        -- remove old members who left
        for name, online in pairs(old) do
          if not new[name] then
            db("raid", name, " left the raid.")
            addonData.summon:remove(name)
            inzone[name] = nil
          end
        end
      end
    end
  end,

  fishArea = function(self)
    if not IsInGroup() then
      return
    end

    local lock = 0
    local click = 0
    if SteaSummonSave.experimental then
      for k, v in pairs(inzone) do
        if v then
          if UnitInRaid(k) and addonData.util:playerClose(k) then
            _, class = UnitClass(k)
            if class == "WARLOCK" and UnitLevel(k) >= 20 then
              lock = lock + 1
            else
              click = click + 1
            end
          end
        end
      end
      SummonFrame.status:SetText("Locks " .. lock .. "\nClickers " ..  click)
    end
    return lock,click
  end
}

addonData.raid = raid