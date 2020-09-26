-- Raid tracking
local addonName, addonData = ...

-- events of interest
-- GROUP_ROSTER_UPDATE
-- PARTY_LEADER_CHANGED
-- NAME_PLATE_UNIT_REMOVED
-- NAME_PLATE_UNIT_ADDED

--GetRaidRosterInfo(1..40)
--UnitInRaid("unit")

local old, new = {}, {}
local roster = {}
local rosterOld = {}
local inzone = {}

local raid = {
  init = function(self)
    addonData.debug:registerCategory("raid.event")
  end,

  callback = function(self, event, ...)
    db("event", event, ...)

    if (event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE") then
      addonData.raid:updateRaid()
    end

    if (event == "PARTY_LEADER_CHANGED") then
      addonData.gossip:initialize()
    end
  end,

  updateRaid = function(self)
      old, new = new, old
      roster, rosterOld = rosterOld, roster
      wipe(new)
      wipe(roster)
      for i = 1, GetNumGroupMembers() do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, loot = GetRaidRosterInfo(i)
        new[name] = online
        roster[name] = 1

        if rosterOld[name] == nil then
          db("raid", name, "joined the raid.")
        end

        if (old[name] or rosterOld[name] == nil) and not online then
          db("raid", name, "is offline.")
          addonData.summon:offline(name, true)
        elseif not (old[name] or rosterOld[name] == nil) and online then
          db("raid", name, "logged back on.")
          addonData.summon:offline(name, false)
        end

        if isDead then
          db("raid", name, "is dead.")
          addonData.summon:dead(name, true)
        else
          addonData.summon:dead(name, false)
        end

        if zone == GetZoneText() then
          if not inzone[name] then
            db("raid", name, "is in zone.")
            inzone[name] = true
          end
        else
          if inzone[name] then
            db("raid", name, "left the zone.")
            inzone[name] = nil
          end
        end
      end

      -- remove old members who left
      for k, _ in pairs(rosterOld) do
        if not roster[k] then
          db("raid", k, " left the raid.")
          addonData.summon:remove(k)
          inzone[name] = nil
        end
      end
  end,

  fishArea = function(self)
    if not IsInGroup() then
      return
    end

    if SteaSummonSave.experimental then
      self:updateRaid()

      local lock = 0
      local click = 0
      if addonData.util:playerCanSummon() then
        lock = 1
      else
        click = 1
      end

      for k, v in pairs(inzone) do
        if UnitInRaid(k) and addonData.util:playerClose(k) then
          if addonData.util:playerCanSummon(k) then
            lock = lock + 1
          else
            click = click + 1
          end
        end
      end
      SummonFrame.status:SetText("Locks " .. lock .. "\nClickers " ..  click)
    end
    return lock,click
  end,
}

addonData.raid = raid