local addonName, addonData = ...

local util = {
  trim = function(self, s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
  end,

  tableToMultiLine = function(self, table)
    local text = ""
    for i,word in pairs(table) do
      text = text .. word .. "\n"
    end
    return text
  end,

  case = function(self, text, sep)
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

  multiLineToTable = function(self, text)
    return { strsplit("\n", text) }
  end,

  marshalWaitingTable = function(self, table)
    local out = ""

    for i, wait in pair(addonData.summon.waiting) do
      out = out .. wait[0] .. "+" .. wait[1] .. "+" .. wait[3] .. ","
    end

    return out
  end,

  unmarshalWaitingTable = function(self, marshalled)
    local recs = { strsplit(",", marshalled) }
    for i, rec in pair(recs) do
      local player, time, status = strsplit("+", rec)
      if addonData.summon:findWaitingPlayer(player) == nil then
        table.insert(addonData.summon.waiting, {player, time, status})
      end
    end
    self:sortWaitingTableByTime()
  end,

  sortWaitingTableByTime = function(self)
    table.sort(addonData.summon.waiting, function(k1, k2)
      return k1[3] > k2[3]
    end)
  end,

  playerClose = function(self, player)
    local me, void = UnitName("player")
    player = strsplit("-", player) -- might turn up as player-server

    if SteaSummonSave.debug then
      if me == player or player == "player" then
        return false -- don't trip for yourself, we'll let others tell us you're summoned :)
      end
    end

    return IsSpellInRange("Unending Breath", player)
  end,

  playerCanSummon = function(self, player)
    local server
    if player == nil then player = "player" end

    player = strsplit("-", player) -- might turn up as player-server

    local class, englishClass = UnitClass(player)
    local level = UnitLevel(player)
    return class == "Warlock" and level >= 20
  end,
}

addonData.util = util