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

  playerClose = function(_, player)
    local me, _ = UnitName("player")
    player = strsplit("-", player) -- might turn up as player-server
    --print("player", player)

    if me == player or player == "player" then
      return false -- don't trip for yourself, we'll let others tell us you're summoned :)
    end

    if UnitInRange(player) then
      return true
    end
    --return addonData.raid.inzone[player]
  end,

  playerIsWarlock = function(_, player)
    if player == nil then player = "player" end
    player = strsplit("-", player) -- might turn up as player-server
    local _, class = UnitClass(player)

    return class == "WARLOCK"
  end,

  playerCanSummon = function(self, player)
    if player == nil then player = "player" end
    player = strsplit("-", player) -- might turn up as player-server

    local level = UnitLevel(player)
    return self:playerIsWarlock(player) and level >= 20
  end,
}

addonData.util = util