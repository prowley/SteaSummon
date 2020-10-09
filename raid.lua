-- Raid tracking
local _, addonData = ...
local L = LibStub("AceLocale-3.0"):GetLocale("SteaSummon")

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

    end

    if (event == "PARTY_LEADER_CHANGED") then
      addonData.summon:postInitSetup()
      addonData.raid.groupInit = false
    end
  end,

  updateRaid = function(self)
    if addonData.raid.groupInit then
      return
    end
    roster, rosterOld = rosterOld, roster
    wipe(roster)

    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then
      addonData.raid.groupInit = true
      addonData.gossip:raidLeft()
    end

    for i = 1, GetNumGroupMembers() do
      local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, loot = GetRaidRosterInfo(i)
      --db("raid", "enum:", name, rank, subgroup, level, class, fileName, zone, online, isDead, role, loot)
      if name == nil then
        break -- protect the list
      end
      roster[name] = 1

      if rosterOld[name] == nil then
        db("raid", name, "joined the raid.")
        local myName, _ = UnitName("player")
        if myName == name then
          addonData.gossip:raidJoined()
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
          addonData.summon:listClear()
          wipe(rosterOld)
          addonData.raid.groupInit = true
        else
          addonData.gossip:raiderLeft(k)
        end

        self.inzone[k] = nil
      end
    end
  end,

  fishArea = function(self)
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then
      return
    end

    self:updateRaid()

    local lock = 0
    local click = 0

    if SteaSummonSave.experimental then
      --[[----------------
            EXPERIMENTAL
      --------------------]]
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
      SteaSummonFrame.status:SetText(L["Warlocks"] .. " " .. lock .. "\n" .. L["Clickers"] .. " "..  click)
      --[[----------------
            EXPERIMENTAL
      --------------------]]
    end

    return lock,click
  end,
}

addonData.raid = raid