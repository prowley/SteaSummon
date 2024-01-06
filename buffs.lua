local _, addonData = ...

City = {
  16609, --"WarChief's Blessing",
  22888, --"Rallying Cry of the Dragonslayer",
  24425, --"Spirit of Zandalar",
  430947, --"Boon of BlackFathom",
}

DarkMoon = {
  23768, --"Sayge's Dark Fortune of Damage",
  23769, --"Sayge's Dark Fortune of Resistance",
  23767, --"Sayge's Dark Fortune of Armor",
  23766, --"Sayge's Dark Fortune of Intelligence",
  23738, --"Sayge's Dark Fortune of Spirit",
  23737, --"Sayge's Dark Fortune of Stamina",
  23735, --"Sayge's Dark Fortune of Strength",
  23737, --"Sayge's Dark Fortune of Agility",
}

DireMaul = {
  22818, --"Mol'dar's Moxie",
  22817, --"Fengus' Ferocity",
  22820, --"Slip'kik's Savvy",
}

Felwood = {
  15366, --"Songflower Serenade",
}

TimeSensitive = {
  City,
  DarkMoon,
  DireMaul,
  Felwood
}

buffs = {
  buffs = {},

  init = function(self)
    addonData.debug:registerCategory("buffs")
    -- build the buff table
    for _, set in pairs(TimeSensitive) do
      for _, b in pairs(set) do
        db("registering buff", b)
        self.buffs[b] = 1
      end
    end
  end,

  report = function(self, player)
    local out, index, i = {}, 1, 1

    while true do
      local name, icon, _, _, _, _, _, _, _, spellId = UnitBuff(player, index)

      index = index + 1

      if name == nil then
        break
      end

      db("buffs", player, "has buff", name)
      if self.buffs[spellId] then
        db("buffs", name, "is of interest")
        out[i] = {spellId, icon}
        i = i + 1
      end
    end

    return out
  end,

  marshallBuffs = function(self, buffs)
    local out = ""
    local spacer = ""
    for _,v in pairs(buffs) do
      if #v > 0 then
        db("buffs", v[1])
        out = out .. spacer .. v[1] .. "~" .. v[2]
        spacer = "&"
      end
    end
    db("buffs", "buffs marshalled", out)
    return out
  end,

  unmarshallBuffs = function(self, marshalled)
    local out = {}
    db("buffs", "unmarshalling", marshalled)
    if not marshalled or marshalled == "" then
      return out
    end

    local tmpOut = { strsplit("&", marshalled) }
    for i,v in pairs(tmpOut) do
      if not (v == nil or v == "") then
        db("buffs", "unmarshalling", v)
        out[i] = { strsplit("~", v) }
      end

      db("buffs", "buff unmarshalled", out[i][1], out[i][2])
    end

    return out
  end,
}

addonData.buffs = buffs
