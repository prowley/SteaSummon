local addonName, addonData = ...

City = {
  16609, --"WarChief's Blessing",
  22888, --"Rallying Cry of the Dragonslayer",
  24425, --"Spirit of Zandalar",
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
      local name, rank, icon, count, debuffType, duration,
        expirationTime, unitCaster, isStealable,
        shouldConsolidate, spellId
        = UnitBuff(player, index)

      index = index + 1

      if name == nil then
        break
      end

      db("buffs", player, "has buff", name)
      if self.buffs[spellId] then
        db("buffs", name, "is of interest")
        out[i] = {spellId, name, icon}
        i = i + 1
      end
    end

    return out
  end,
}

addonData.buffs = buffs