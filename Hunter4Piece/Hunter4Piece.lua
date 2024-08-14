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
local creatureToBuff = {
  ["Humanoid"] = "Humanoid Slaying",
  ["Elemental"] = "Elemental Slaying",
  ["Giant"] = "Giant Slaying",
  ["Beast"] = "Beast Slaying",
  ["Demon"] = "Demon Slaying",
  ["Undead"] = "Undead Slaying",
  ["Dragonkin"] = "Dragon Slaying"
}
local autoApply4Piece = true
local toggleName = "4pieceToggle"
local activeName = "4pieceActivate"
local huntersMark = 132212
local spiritIcon = 136116
local function isActive(creatureType)
  if (_G.AuraUtil and _G.AuraUtil.FindAuraByName) then
    local auraName = creatureToBuff[creatureType]
    if (auraName) then
      local isActive, _ = _G.AuraUtil.FindAuraByName(auraName, "player")
      return isActive
    end
  end

  return false
end

local function createMacros()
  if (_G.GetMacroIndexByName and _G.CreateMacro) then
    local toggleExists = _G.GetMacroIndexByName(toggleName)
    local activeExists = _G.GetMacroIndexByName(activeName)

    if (toggleExists == 0) then
      _G.CreateMacro(toggleName, spiritIcon, "/run toggleFourPiece()", false)
      if (_G.GetMacroIndexByName(toggleName) ~= 0) then
        print("A macro has been created for you to toggle the automatic tracking behavior.\nSee " .. toggleName)
      end
    end

    if (activeExists == 0) then
      _G.CreateMacro(activeName, huntersMark, "/run sodFourPiece()", false)
      if (_G.GetMacroIndexByName(activeName) ~= 0) then
        print("A macro has been created for you to manually apply the correct tracking based on your target.\nSee " ..
          activeName)
      end
    end
  end
end

function sodFourPiece()
  if (_G.UnitCreatureType and _G.CastSpellByName and _G.UnitCanAttack) then
    local creatureType = _G.UnitCreatureType("target")
    local hostile = _G.UnitCanAttack("player", "target")
    if (creatureType and hostile and not isActive(creatureType)) then
      local spellName = creatureToSpell[creatureType]
      _G.CastSpellByName(spellName)
    end
  end
end

function toggleFourPiece()
  autoApply4Piece = not autoApply4Piece
  local msg = autoApply4Piece and "Enabled" or "Disabled"
  print("Hunter Four Piece Bonus automation is now: " .. msg)
end

function Hunter4Piece.EventHandler:PLAYER_TARGET_CHANGED(...)
  createMacros()
  if (autoApply4Piece) then
    sodFourPiece()
  end
end

Hunter4Piece:SetScript("OnEvent", function(self, event, ...)
  Hunter4Piece.EventHandler[event](self, ...)
end)

for k, v in pairs(Hunter4Piece.EventHandler) do
  Hunter4Piece:RegisterEvent(k)
end
