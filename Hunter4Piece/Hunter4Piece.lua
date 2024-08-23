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

function sodFourPiece(targetChanged)
  if (_G.UnitCastingInfo) then
    local isCasting = _G.UnitCastingInfo("player")
    if (isCasting) then
      return false
    end
  end
  if (_G.UnitPlayerControlled and _G.UnitCreatureType and _G.CastSpellByName and _G.UnitCanAttack and _G.UnitIsDead) then
    local creatureType = _G.UnitCreatureType("target")
    local hostile = _G.UnitCanAttack("player", "target")
    local isAlive = not _G.UnitIsDead("target")
    local allowPlayer = not _G.UnitPlayerControlled("target")
    if (not targetChanged) then
      -- allow manual macro to do the right tracking always
      isAlive = true
      hostile = true
      allowPlayer = true
    end
    if (allowPlayer and isAlive and creatureType and hostile and not isActive(creatureType)) then
      local spellName = creatureToSpell[creatureType]
      if (spellName) then
        _G.CastSpellByName(spellName, "player")
      end
    end
  end
end

function toggleFourPiece()
  Hunter4Piece_SavedVariables.autoApply4Piece = not Hunter4Piece_SavedVariables.autoApply4Piece
  local msg = Hunter4Piece_SavedVariables.autoApply4Piece and "Enabled" or "Disabled"
  print("Hunter Four Piece Bonus automation is now: " .. msg)
end

function Hunter4Piece.EventHandler:PLAYER_TARGET_CHANGED(...)
  createMacros()
  if (Hunter4Piece_SavedVariables.autoApply4Piece) then
    sodFourPiece(true)
  end
end

function Hunter4Piece.EventHandler:ADDON_LOADED(...)
  local AddOnName = select(1, ...)
  if (AddOnName == "Hunter4Piece") then
    Hunter4Piece_SavedVariables = Hunter4Piece_SavedVariables or {}
    if (Hunter4Piece_SavedVariables.autoApply4Piece == nil) then
      Hunter4Piece_SavedVariables.autoApply4Piece = true
    end
  end
end

Hunter4Piece:SetScript("OnEvent", function(self, event, ...)
  Hunter4Piece.EventHandler[event](self, ...)
end)

for k, v in pairs(Hunter4Piece.EventHandler) do
  Hunter4Piece:RegisterEvent(k)
end
