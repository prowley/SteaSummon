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

local raid = {
  guids = {},

  callback = function(self, event, ...)
    local arg1, arg2, arg3, arg4, arg5, arg6, arg7 = ...
    db(event, " ", arg1, " ", arg2, " ", arg3, " ", arg4, " ", arg5, " ", arg6, " ", arg7)

    if (event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED") then
      -- stuff has happenned, maybe we joined a group - might be a bit chatty
      addonData.gossip:initialize()
    end

    if event == "NAME_PLATE_UNIT_ADDED" then
      guids[UnitGUID(arg1)] = arg1
    end

    if event == "NAME_PLATE_UNIT_REMOVED" then
      self.guids[UnitGUID(arg1)] = nil
    end
  end,

  fishArea = function(self)
    local lock = 0
    local click = 0
    if UnitClass("player") == "Warlock" and UnitLevel("player") >= 20 then
      lock = 1
    else
      click = 1
    end
    for k, v in pairs(self.guids) do
      if UnitInRaid(v) then
        if UnitClass(v) == "Warlock" and UnitLevel(v) >= 20 then
          lock = lock + 1
        else
          click = click + 1
        end
      end
    end
    SummonFrame.status:SetText("Locks " .. lock .. " Clickers " ..  click)
    return lock,click
  end
}

addonData.raid = raid