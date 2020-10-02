-- Raid tracking
local _, addonData = ...

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
  groupInit = true,

  init = function(self)
    addonData.debug:registerCategory("raid.event")
    if IsInGroup(LE_PARTY_CATEGORY_HOME) then
      self.groupInit = false
    end
  end,

  callback = function(_, event, ...)
    db("raid.event", event, ...)

    if (event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE") then
      addonData.raid:updateRaid()
    end

    if (event == "PARTY_LEADER_CHANGED") then
      addonData.raid.groupInit = false
    end
  end,

  updateRaid = function(self)
    if addonData.raid.groupInit then
      return
    end
    roster, rosterOld = rosterOld, roster
    old, new = new, old
    wipe(new)
    wipe(roster)

    for i = 1, GetNumGroupMembers() do
      local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, loot = GetRaidRosterInfo(i)
      --db("raid", "enum:", name, rank, subgroup, level, class, fileName, zone, online, isDead, role, loot)
      if name == nil then
        -- I want to know if this ever fires, even if I am not monitoring the raid category
        db("Got a nil back for name", name, rank, subgroup, level, class, fileName, zone, online, isDead, role, loot)
        break -- protect the list
      end
      new[name] = online or nil
      roster[name] = 1

      if rosterOld[name] == nil then
        db("raid", name, "joined the raid.")
        local myName, _ = UnitName("player")
        if myName == name then
          addonData.gossip:raidJoined()
        end
      end

      if (old[name] or rosterOld[name] == nil) and not online then
        db("raid", name, "is offline.")
        addonData.gossip:raiderLeft(name)
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

      if zone == GetMinimapZoneText() then
        if not self.inzone[name] then
          db("raid", name, "is near,", zone)
          self.inzone[name] = true
        end
      else
        if self.inzone[name] then
          db("raid", name, "left area, now in", zone)
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

        local name, _ = UnitName("player")
        if k == name then
          addonData.gossip:raidLeft()
          wipe(addonData.summon.waiting)
          wipe(old)
          wipe(rosterOld)
          addonData.raid.groupInit = true
        else
          addonData.gossip:raiderLeft(k)
        end

        self.inzone[k] = nil
      end
    end
  end,

  isDead = function(_, player)
    return dead[player] == true
  end,

  isOffline = function(_, player)
    return new[player] == nil
  end,

  fishArea = function(self)
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then
      return
    end

    self:updateRaid()

    local lock = 0
    local click = 0

    if addonData.util:playerCanSummon() then
      lock = 1
    else
      click = 1
    end

    for k, _ in pairs(self.inzone) do
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