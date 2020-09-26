local addonName, addonData = ...

City = {
  "WarChief's Blessing",
  "Rallying Cry of the Dragonslayer",
  "Spirit of Zandalar",
}

DarkMoon = {
  "Sayge's Dark Fortune of Damage",
  "Sayge's Dark Fortune of Resistance",
  "Sayge's Dark Fortune of Armor",
  "Sayge's Dark Fortune of Intelligence",
  "Sayge's Dark Fortune of Spirit",
  "Sayge's Dark Fortune of Stamina",
  "Sayge's Dark Fortune of Strength",
  "Sayge's Dark Fortune of Agility",
}

DireMaul = {
  "Mol'dar's Moxie",
  "Fengus' Ferocity",
  "Slip'kik's Savvy",
}

Felwood = {
  "Songflower Serenade",
  "Windblossom Berries",
  "Whipper Root Tuber",
  "Night Dragon's Breath",
}

BlastedLands = {
  "R.O.I.D.S.",
  "Ground Scorpak Assay",
  "Lung Juice Cocktail",
  "Cerebral Cortex Compound",
  "Gizzard Gum",
}

Winterspring = {
  "Juju Might",
  "Juju Power",
  "Juju Flurry",
  "Juju Gulie",
  "Juju Escape",
  "Juju Chill",
  "Juju Ember"
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
    local out, index = {}, 1

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
      if self.buffs[name] then
        db("buffs", name, "is of interest")
        out[index] = {name, icon, (GetTime() - expirationTime) / 60}
      end
    end

    if #out == 0 then
      out = nil
    end

    return out
  end,
}

addonData.buffs = buffs