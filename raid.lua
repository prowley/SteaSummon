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

local dead = {}


local raid = {
  inzone = {},
  caninvite = {},

  init = function(self)
    addonData.debug:registerCategory("raid.event")
  end,

  callback = function(self, event, ...)
    db("raid.event", event, ...)

    if (event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE") then
      --addonData.raid:updateRaid()
    end

    if (event == "PARTY_LEADER_CHANGED") then
      db("raid", event)
      addonData.gossip:initialize()
    end
  end,

  updateRaid = function(self)
    roster, rosterOld = rosterOld, roster
    old, new = new, old
    wipe(new)
    wipe(roster)
    local lastGroupNum = GetNumGroupMembers()
    for i = 1, GetNumGroupMembers() do
      local sizeNow = GetNumGroupMembers()
      if (lastGroupNum ~= sizeNow) then
        -- I want to know if this ever fires, even if I am not monitoring the raid category
        db("Group size was", lastGroupNum, "but is now", sizeNow)
        break -- protect the list
      end
      local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, loot = GetRaidRosterInfo(i)
      if name == nil then
        -- I want to know if this ever fires, even if I am not monitoring the raid category
        db("Got a nil back for name", name, rank, subgroup, level, class, fileName, zone, online, isDead, role, loot)
        break -- protect the list
      end
      new[name] = online or nil
      roster[name] = 1

      if rosterOld[name] == nil then
        db("raid", name, "joined the raid.")
      end

      if (old[name] or rosterOld[name] == nil) and not online then
        db("raid", name, "is offline.")
        addonData.summon:offline(name, true)
      elseif old[name] == nil and rosterOld[name] and online then
        db("raid", name, "logged back on.")
        addonData.summon:offline(name, false)
      end

      if isDead and not dead[name] then
        db("raid", name, "is dead.")
        addonData.summon:dead(name, true)
        dead[name] = 1
      elseif not isDead and dead[name] then
        addonData.summon:dead(name, false)
        dead[name] = nil
      end

      if zone == GetZoneText() then
        if not self.inzone[name] then
          db("raid", name, "is in zone.")
          self.inzone[name] = true
        end
      else
        if self.inzone[name] then
          db("raid", name, "left the zone.")
          self.inzone[name] = nil
        end
      end

      if rank > 0 then
        self.caninvite[name] = true
      else
        self.caninvite[name] = false
      end
    end

    -- remove old members who left
    for k, _ in pairs(rosterOld) do
      if not roster[k] then
        db("raid", k, " left the raid.")
        addonData.summon:remove(k)
        self.inzone[k] = nil
      end
    end
  end,

  isDead = function(self, player)
    return dead[player] == true
  end,

  isOffline = function(self, player)
    return new[player] == nil
  end,

  fishArea = function(self)
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then
      return
    end

    self:updateRaid()

    local lock = 0
    local click = 0

    for k, v in pairs(self.inzone) do
      if UnitInRange(k) then
        if addonData.util:playerCanSummon(k) then
          lock = lock + 1
        else
          click = click + 1
        end
      end
    end
    SummonFrame.status:SetText("Locks " .. lock .. "\nClickers " ..  click)

    return lock,click
  end,
}

addonData.raid = raid