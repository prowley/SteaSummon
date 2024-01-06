local _, addonData = ...

local util = {
  init = function(_)
    addonData.debug:registerCategory("util")
  end,

  trim = function(_, s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
  end,

  tableToMultiLine = function(_, table, sep)
    local text = ""
    local word
    if sep == nil then
      sep = ", "
    end
    local ins = ""
    for key, val in pairs(table) do
      if type(val) == "string" then
        word = val
      else
        word = key
      end
      if word ~= "" then
        text = text .. ins .. word
        if ins == "" then
          ins = sep
        end
      end
    end
    return text
  end,

  multiLineToTable = function(_, text, sep)
    -- might be comma or carriage return delimited
    if not sep and string.find(text, ",") then
      sep = ","
    else
      sep = "\n"
    end
    local out = {strsplit(sep, text)}

    -- sanitize
    local idx = 1
    for _,v in pairs(out) do
      local sanitized = strtrim(v)
      if sanitized ~= "" then
        out[idx] = sanitized
        idx = idx + 1
      end
    end

    return out
  end,

  multiLineToMap = function(self,text, sep)
    local tbl = self:multiLineToTable(text, sep)
    local map = {}

    for _,v in pairs(tbl) do
      map[v] = 1
    end

    return map
  end,

  case = function(_, text, sep)
    local out = ""
    if text ~= nil and text ~= "" then
      local i = 2
      local last = 2
      out = strupper(strsub(text,1,1))
      while(i ~= nil) do
        i = strfind(text, sep, i)
        if i ~= nil then
          out = out .. strsub(text,last,i) .. strupper(strsub(text,i+1,i+1))
          last = i + 2
          i = i + 1
        end
      end
      out = out .. strsub(text,last)
    end
    return out
  end,

  marshalWaitingTable = function()
    db("summon.waitlist", "marshalling waitlist")
    local out = ""
    local comma = ""

    for _, wait in pairs(addonData.summon.waiting) do
      out = out .. comma .. addonData.summon:recMarshal(wait)
      if comma == "" then
        comma = ","
      end
    end

    db("summon.waitlist", "marshalled waitlist:", out)
    return out
  end,

  unmarshalWaitingTable = function(_, marshalled)
    db("summon.waitlist", "unmarshalling waitlist:", marshalled)
    wipe(addonData.summon.waiting)
    if not marshalled or marshalled == "" then
      addonData.summon.numwaiting = 0
      return
    end
    local recs = { strsplit(",", marshalled) }
    local waiting = {}
    local numwaiting = 0
    if recs and #recs > 0 then
      for _, rec in pairs(recs) do
        table.insert(waiting, addonData.summon:recUnMarshal(rec))
        numwaiting = numwaiting + 1
      end
    end
    addonData.summon.waiting = waiting
    addonData.summon.numwaiting = numwaiting
    addonData.summon:listDirty(true)
    addonData.summon:showSummons()
  end,

  sortWaitingTableByTime = function()
    table.sort(addonData.summon.waiting, function(k1, k2)
      return k1[3] > k2[3]
    end)
  end,

  isInTable = function(_, tbl, item)
    local inTable = false

    for _,v in pairs(tbl) do
      if v == item then
        inTable = true
        break
      end
    end

    return inTable
  end,

  playerClose = function(self, player)
    local me, _ = UnitName("player")
    player = strsplit("-", player) -- might turn up as player-server

    if me == player or player == "player" then
      return false -- don't trip for yourself, we'll let others tell us you're summoned :)
    end

    if UnitInRange(player) or self:isNear(player) then
      return true
    end
  end,

  playerIsWarlock = function(_, player)
    if player == nil then player = "player" end
    player = strsplit("-", player) -- might turn up as player-server
    local _, class = UnitClass(player)

    return class == "WARLOCK"
  end,

  playerCanSummon = function(self, player)
    self = addonData.util
    if player == nil then player = "player" end
    player = strsplit("-", player) -- might turn up as player-server

    local level = UnitLevel(player)
    return self:playerIsWarlock(player) and level >= 20
  end,

  distance = function(_, unit1, unit2)
    local out
    local y1, x1, _, instance1 = UnitPosition(unit1)
    local y2, x2, _, instance2 = UnitPosition(unit2)
    if y1 and x1 and x2 and y2 then
      if instance1 == instance2 then
        out = ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
      end
    end
    return out
  end,

  isNear = function(self, player)
    local ret = false
    local dist = self:distance("player", player)
    if dist ~= nil and dist <= 40 then
      db("util", "player detected by alt method")
      ret = true
    end
    return ret
  end,
}

addonData.util = util
