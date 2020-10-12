local _, addonData = ...

local summon
local util
local chat
local gossip

local alt = {
  me = "",
  playersInConversation = {},

  init = function(self)
    addonData.debug:registerCategory("alt")
    self.me, _ = UnitName("player")
    summon = addonData.summon
    util = addonData.util
    chat = addonData.chat
    gossip = addonData.gossip
  end,

  newPlayer = function(self, player)
    if player == self.me then
      for _,v in pairs(SteaSummonSave.alttoons) do
        db("alt", "mytoon:", v)
      end
      if #SteaSummonSave.alttoons > 0 then
        db("alt", "adding my own toons as alts")
        gossip:alts(player, SteaSummonSave.alttoons)
      end
      return
    end
  end,

  listWhisper = function(_, upTo, boost)
    -- maybe some convos get triggered
    local i = 1
    local boosted = 0

    if upTo == nil then
      upTo = summon.numwaiting
    end

    db("alt", "checking list for offlines with alts")
    while(i <= summon.numwaiting and i <= upTo) do
      local rec = summon.waiting[i]
      local player = summon:recPlayer(rec)

      db("alt", "player", player)
      if summon:recStatus(rec) == "offline" and summon:recAltWhispered(rec) == "" and #summon:recAlts(rec) > 0 then
        db("alt", "offline with alts")
        for _,alt in pairs(summon:recAlts(rec)) do
          db("alt", "whispering", alt)
          chat:whisper(SteaSummonSave.altGetOnlineWhisper, alt)
          summon:recAltWhispered(rec, summon:recAltWhispered(rec) .. alt .. ",")
          gossip:altWhispered(summon:recPlayer(rec), alt)
        end
        boosted = boosted + 1
        if boost and boosted == boost then
          break
        end
      end
      i = i + 1
    end
  end,

  listShorter = function(self)
    local upTo = SteaSummonSave.qspot
    if upTo == 0 or upTo == 41 then
      return
    end

    self:listWhisper(upTo)
  end,

  listBoost = function(self)
    local boost = SteaSummonSave.qboost
    if boost == 0 then
      return
    end

    self:listWhisper(nil, boost)
  end,

  whispered = function(_, player, text)
    db("alt", "whispered", text, "from", player)
    local wait = summon:findWaitingPlayer(player)
    if not wait or summon:recStatus(wait) ~= "requested" then
      -- filter out thank yous and such (because the world is asynchronous)
      -- and random whispers, because the whole world is not in your raid
      return
    end

    -- let's see if this is a single word or a list of words
    local alts = {}
    local words = util:multiLineToTable(text, ",")
    for _, v in pairs(words) do
      local alt = strtrim(v)
      if string.find(v, " ") then
        -- probably indicates something other than an alt or list of alts
        -- otoh, failure conditions include lmao, plz, and other drivel, let's hope those aren't real toons
        db("alt", "spaces found")
        return
      end
      table.insert(alts, alt)
    end

    if #alts > 0 then
      -- probably have an alt list, or some very angry people called plz and lmao
      gossip:alts(player, alts)
    end
  end,

  askForAlts = function(_, player)
    local idx = summon:findWaitingPlayerIdx(player)

    if gossip.netList[player] then
      --return -- addon users can configure if they want alts
    end

    if SteaSummonSave.altbuffed and #summon:recBuffs(summon.waiting[idx]) == 0 then
      return
    end

    if SteaSummonSave.initialQspot <= idx then
      -- we need to talk
      chat:whisper(SteaSummonSave.altWhisper, player)
    end
  end,
}

addonData.alt = alt