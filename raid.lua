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

local inzone = {}
local old, new = {}, {}

local raid = {
    callback = function(self, event, ...)
      local arg1, arg2, arg3, arg4, arg5, arg6, arg7 = ...

      if SteaSummonSave.experimental then
        db(event, " ", arg1, " ", arg2, " ", arg3, " ", arg4, " ", arg5, " ", arg6, " ", arg7)

        -- for now, this is in observe mode until I understand how this event works
        -- it could drive addon network leader election cycle, keep track of close online players
        if (event == "RAID_ROSTER_UPDATE") then
          old, new = new, old
          wipe(new)
          wipe(inzone)
          for i = 1, GetNumRaidMembers() do
            local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, loot = GetRaidRosterInfo(i)
            new[name] = online or false
            if zone == GetZoneText() then
              inzone[name] = true
            end
            if old[name] == nil then
              db(name, " joined the raid.")
            elseif old[name] and not online then
              db(name, " has gone offline.")
              inzone[name] = false
            elseif online and not old[name] then
              db(name, " logged back on.")
            end
          end
          for name, online in pairs(old) do
            if not new[name] then
              db(name, " left the raid.")
            end
          end
        end
      end
  end,

  fishArea = function(self)
    local lock = 0
    local click = 0
    if SteaSummonSave.experimental then
      if UnitClass("player") == "Warlock" and UnitLevel("player") >= 20 then
        lock = 1
      else
        click = 1
      end
      for k, v in pairs(inzone) do
        if v then
          if UnitInRaid(k) then
            if UnitClass(k) == "Warlock" and UnitLevel(k) >= 20 then
              lock = lock + 1
            else
              click = click + 1
            end
          end
        end
      end
      SummonFrame.status:SetText("Locks " .. lock .. " Clickers " ..  click)
    end
    return lock,click
  end
}

addonData.raid = raid