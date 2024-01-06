-- Raid tracking
local _, addonData = ...

local buffs
local util

-- SetLootMethod("method" [,"masterPlayer" or threshold])

local raid = {
  caninvite = {},
  roster = {},
  rosterOld = {},
  clickers = {},
  me = "",

  init = function(self)
    addonData.debug:registerCategory("raid.event")
    buffs = addonData.buffs
    util = addonData.util
    self.me = UnitName("player")
  end,

  callback = function(self, event, ...)
    db("raid.event", event, ...)

    self = addonData.raid

    if (event == "GROUP_ROSTER_UPDATE" or event == "RAID_ROSTER_UPDATE") then
      self:updateRaid()
      self:assign()
    end

    if (event == "PARTY_LEADER_CHANGED") then
      if IsInGroup(LE_PARTY_CATEGORY_HOME) then
        self:updateRaid()
        if UnitIsGroupLeader("player") then
          if SteaSummonSave.convertToRaid and not IsInRaid() then
            ConvertToRaid()
          end
          if SteaSummonRelinquishRaidLeadButton then
            SteaSummonRelinquishRaidLeadButton:Show()
          end
        else
          if SteaSummonRelinquishRaidLeadButton then
            SteaSummonRelinquishRaidLeadButton:Hide()
          end
        end

        self:assign()
      else
        if SteaSummonRelinquishRaidLeadButton then
          SteaSummonRelinquishRaidLeadButton:Hide()
        end
      end
    end
  end,

  updateRaid = function(self)
    self.roster, self.rosterOld = self.rosterOld, self.roster
    wipe(self.roster)

    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then
      addonData.summon:listClear()
      addonData.gossip:raidLeft()
      wipe(self.rosterOld)
      return
    end

    for i = 1, GetNumGroupMembers() do
      local name, rank = GetRaidRosterInfo(i)
      if name ~= nil then
        self.roster[name] = 1

        if self.rosterOld[name] == nil then
          db("raid", name, "joined the raid.")
          if self.me == name then
            addonData.gossip:raidJoined()
          end
        end

        if rank > 0 then
          self.caninvite[name] = true
        else
          self.caninvite[name] = false
        end
      end
    end

    -- remove old members who left
    for k, _ in pairs(self.rosterOld) do
      if not self.roster[k] then
        db("raid", k, " left the raid.")
        addonData.summon:remove(k)

        local name, _ = UnitName("player")
        if k == name then
          addonData.gossip:raidLeft()
          addonData.summon:listClear()
          wipe(self.rosterOld)
          addonData.raid.groupInit = true
        else
          addonData.gossip:raiderLeft(k)
        end
      end
    end
  end,

  fishedClickers = function(self)
    return self.clickers
  end,

  fishArea = function(self)
    if not IsInGroup(LE_PARTY_CATEGORY_HOME) then
      return
    end

    wipe(self.clickers)

    for k, _ in pairs(self.roster) do
      if UnitInRange(k) then
        table.insert(self.clickers, k)
      end
    end

    addonData.gossip:setClicks()
  end,

  isInvTrigger = function(_, trigger)
    for _,v in pairs(SteaSummonSave.autoInviteTriggers) do
      if v == trigger then
        return true
      end
      return false
    end
  end,

  inGuild = function(_, player)
    local _, server = UnitFullName("player")
    local gNum = GetNumGuildMembers()
    for i=1, gNum do
      local guildy = GetGuildRosterInfo(i)
      if player == guildy then
        return true
      end
      if player .. "-" .. server == guildy then
        return true
      end
    end
    return false
  end,

  whisperedTrigger = function(self, player)
    local setting = SteaSummonSave.autoInvite

    if setting == 4 or UnitInRaid(player) then
      return
    end

    if setting == 1 then
      db("raid", "auto invites set to guild")
      if not self:inGuild(player) then
        db("raid", "requester not in guild")
        return
      end
      db("raid", "requester in guild", player)
    end

    if setting == 2 then
      db("raid", "auto invites set to guild and friends")
      local f = C_FriendList.GetFriendInfo(player)

      if not f then
        db("raid", "requester not a friend")
        if not self:inGuild(player) then
          db("raid", "requester not in guild")
          return
        end
        db("raid", "requester in guild", player)
      end
    end

    InviteUnit(player)
  end,

  acceptInvites = function(self, event, player, isTank, isHealer, isDamage, isNativeRealm,
                           allowMultipleRoles, inviterGUID, isQuestSessionActive)
    db("raid", event, player, isTank, isHealer, isDamage, isNativeRealm,
        allowMultipleRoles, inviterGUID, isQuestSessionActive)
    self = addonData.raid
    local setting = SteaSummonSave.autoAccept

    if setting == 4 then
      db("raid", "invites set to off")
      return
    end

    if setting == 1 then
      db("raid", "invites set to guild")
      if not self:inGuild(player) then
        db("raid", "invite not in guild")
        return
      end
      db("raid", "inviter in guild", player)
    end

    if setting == 2 then
      db("raid", "invites set to guild and friends")
      local friend =  C_FriendList.IsFriend(inviterGUID)
      db("raid", "it's", friend, "that inviter is friend", player)
      if not friend then
        db("raid", "invite not a friend")
        if not self:inGuild(player) then
          db("raid", "invite not in guild")
          return
        end
        db("raid", "inviter in guild", player)
      end
    end

    db("raid", "accepting group")
    AcceptGroup()
    StaticPopup_Hide("PARTY_INVITE")
  end,

  assign = function(self)
    self = addonData.raid
    if UnitIsGroupLeader("player") then
      local leader
      local gNum = GetNumGroupMembers()

      for i = 1, gNum do
        local name, rank = GetRaidRosterInfo(i)
        local set = false
        if name and name ~= "" and rank == 0 then
          db("raid", "leader testing", name)
          if SteaSummonSave.warlocksAssist and util:playerCanSummon(name) and #buffs:report(name) == 0 then
            set = true
          else
            for _,v in pairs(SteaSummonSave.assistPlayers) do
              if name == v then
                set = true
                break
              end
            end
          end

          if not set then
            for _,v in pairs(SteaSummonSave.raidLeaders) do
              if name == v then
                if not leader then
                  leader = name
                end
                set = true
                break
              end
            end
          end

          if not set then
            for _,v in pairs(SteaSummonSave.masterLoot) do
              if name == v then
                set = true
                break
              end
            end
          end

          db("raid", "should promote:", set)
          if set and name ~= self.me then
            PromoteToAssistant(name)
          end
        end
      end

      if not SteaSummonSave.delayLeadership and leader and leader ~= self.me then
        self:relinquish()
      end
    end
  end,

  relinquish = function(self)
    self = addonData.raid
    if UnitIsGroupLeader("player") then
      local leader, ML = {}, {}

      local gNum = GetNumGroupMembers()
      for i = 1, gNum do
        local name, rank = GetRaidRosterInfo(i)
        local set = false

        if name and name ~= "" and rank > 0 then
          for _,v in pairs(SteaSummonSave.assistPlayers) do
            db('raid', "assist checking:", v, "=", name)
            if v and name == v then
              set = true
              break
            end
          end

          for _,v in pairs(SteaSummonSave.raidLeaders) do
            db('raid', "raid lead checking:", v, "=", name)
            if v and name == v then
              leader[name] = 1
              set = true
            end
          end

          for _,v in pairs(SteaSummonSave.masterLoot) do
            db('raid', "ML checking:", v, "=", name)
            if v and name == v then
              ML[name] = 1
              set = true
            end
          end

          db("raid", "should demote:", name, not set)
          if not set and name ~= self.me and SteaSummonSave.finalLeadership then
            DemoteAssistant(name)
          end
        end
      end

      db("raid", #ML, "candidates", #leader, "candidates")

      local ml
      for _,v in pairs (SteaSummonSave.masterLoot) do
        db("raid", "checking ML candidate", v, "against", ML[v])
        if ML[v] then
          ml = v
          break
        end
      end
      if ml then
        db("raid", "ML is", ml)
        SetLootMethod("master", ml)
      end

      local l
      for _,v in pairs (SteaSummonSave.raidLeaders) do
        db("raid", "checking raid lead candidate", v, "against", leader[v])
        if leader[v] then
          if v == self.me then
            db("raid", "you are already leader")
            return
          end
          l = v
          break
        end
      end
      if l then
        db("raid", "raid leader is", l)
        PromoteToLeader(l)
      end
    end
  end,
}

addonData.raid = raid
