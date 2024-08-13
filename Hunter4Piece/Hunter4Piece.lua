local Hunter4Piece = CreateFrame("Frame")
Hunter4Piece.EventHandler = {}
local creatureToSpell = {
  ["Humanoid"] = "Track Humanoids",
  ["Elemental"] = "Track Elementals",
  ["Giant"] = "Track Giants",
  ["Beast"] = "Track Beasts",
  ["Demon"] = "Track Demons",
  ["Undead"] = "Track Undead",
  ["Dragonkin"] = "Track Dragonkin"
}
local lastHunterTarget = ""
local enableFourPiece = true
local function sodFourPiece()
  if (enableFourPiece and _G.UnitCreatureType and _G.CastSpellByName and _G.UnitCanAttack) then
    local creatureType = _G.UnitCreatureType("target")
    local hostile = _G.UnitCanAttack("player", "target")
    if (creatureType and lastHunterTarget ~= creatureType and hostile) then
      local spellName = creatureToSpell[creatureType]
      _G.CastSpellByName(spellName)
      lastHunterTarget = creatureType
    end
  end
end

function toggleFourPiece()
  enableFourPiece = not enableFourPiece
  local msg = enableFourPiece and "Enabled" or "Disabled"
  print("Hunter Four Piece Bonus is now: " .. msg)
end

function Hunter4Piece.EventHandler:PLAYER_TARGET_CHANGED(...)
  sodFourPiece()
end

Hunter4Piece:SetScript("OnEvent", function(self, event, ...)
  Hunter4Piece.EventHandler[event](self, ...)
end)

for k, v in pairs(Hunter4Piece.EventHandler) do
  Hunter4Piece:RegisterEvent(k)
end
