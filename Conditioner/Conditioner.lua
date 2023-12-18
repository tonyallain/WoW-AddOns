-- ==============================================CONDITIONER==================================================--
-- By Tony Allain
-- ===========================================================================================================--
-- classic fixups
local currentCastingInfo = {}
local function isClassic()
    return LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CLASSIC
end

local ConditionerGetSpecialization = _G.GetSpecialization or function()
    -- previous implementation stored everyone under WARRIOR
    local _, _, classId = UnitClass("player")
    return classId
end
local ConditionerGetSpecializationInfo = _G.GetSpecializationInfo or
    function(specId)
        return specId, "default", "default specialization",
            "Interface\\FrameGeneral\\UI-Background-Marble"
    end
local ConditionerGetOverrideSpell = _G.C_SpellBook.GetOverrideSpell or function(spellId)
    -- is this a rune?
    if (C_Engraving and C_Engraving.GetRuneForEquipmentSlot) then
        local runeSpellName, _ = GetSpellInfo(spellId)                                    -- gives the spell like Hands/Legs/Chest Rune Ability
        local overrideSpellName, _, _, _, _, _, runeSpellID = GetSpellInfo(runeSpellName) -- by name gives the spell that is currently overriding it
        if (runeSpellID and runeSpellName ~= overrideSpellName) then
            return runeSpellID
        end
    end

    return spellId
end
local ConditionerTransmogUtil = _G.TransmogUtil or {
    GetTransmogLocation = function() end
}
local ConditionerTransmog = _G.C_Transmog or {
    GetSlotInfo = function() end
}
local ConditionerIsSpellOverlayed = _G.IsSpellOverlayed or function() return false end
local ConditionerUnitCastingInfo = isClassic() and function(junk) return unpack(currentCastingInfo) end or
    _G.UnitCastingInfo
local ConditionerUnitChannelInfo = isClassic() and function(junk) return unpack(currentCastingInfo) end or
    _G.UnitChannelInfo
function ClearCastingInfo(castGuid)
    if (castGuid == currentCastingInfo[10]) then
        currentCastingInfo = {}
    end
end

-- ===========================================================================================================--
local ConditionerAddOn = CreateFrame("Frame")
local closeResultsBox = false
local closeResultsBox2 = false
local cropAmount = 0.075
ConditionerAddOn.EventHandler = {}
ConditionerAddOn.DecodePattern = "%[(........................)(_.-_.-_.-_.-_.-_.-])"
ConditionerAddOn.NumConditionsForSecondHalf = 6
ConditionerAddOn.Size = 24 -- the number of wildcards in the first half of the decode pattern
ConditionerAddOn.SpellCache = {}
ConditionerAddOn.ConditionPattern =
"%[(..)(.)(.)(.)(.)(.)(.)(.)(.)(.)(..)(..)(..)(..)(..)(..)(.)_(.-)_(.-)_(.-)_(.-)_(.-)_(.-)]"
ConditionerAddOn.ConditionPatternMatch =
"[%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s]" -- needs to have the same amount as the Condition Pattern above
ConditionerAddOn.BitMap = {
    ["0"] = 0,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["a"] = 10,
    ["b"] = 11,
    ["c"] = 12,
    ["d"] = 13,
    ["e"] = 14,
    ["f"] = 15,
    ["g"] = 16,
    ["h"] = 17,
    ["i"] = 18,
    ["j"] = 19,
    ["k"] = 20,
    ["l"] = 21,
    ["m"] = 22,
    ["n"] = 23,
    ["o"] = 24,
    ["p"] = 25,
    ["q"] = 26,
    ["r"] = 27,
    ["s"] = 28,
    ["t"] = 29,
    ["u"] = 30,
    ["v"] = 31,
    ["w"] = 32,
    ["x"] = 33,
    ["y"] = 34,
    ["z"] = 35,
    ["A"] = 36,
    ["B"] = 37,
    ["C"] = 38,
    ["D"] = 39,
    ["E"] = 40,
    ["F"] = 41,
    ["G"] = 42,
    ["H"] = 43,
    ["I"] = 44,
    ["J"] = 45,
    ["K"] = 46,
    ["L"] = 47,
    ["M"] = 48,
    ["N"] = 49,
    ["O"] = 50,
    ["P"] = 51,
    ["Q"] = 52,
    ["R"] = 53,
    ["S"] = 54,
    ["T"] = 55,
    ["U"] = 56,
    ["V"] = 57,
    ["W"] = 58,
    ["X"] = 59,
    ["Y"] = 60,
    ["Z"] = 61,
    ["?"] = 62,
    ["!"] = 63
}
ConditionerAddOn.DefaultLoadouts = {
    -- DEVASTATION EVOKER WIP
    [1467] = "",
    -- PRESERVATION EVOKER WIP
    [1468] = "",
    -- PROT WARRIOR
    [73] = [=[[02+m0___23920_0_0]
                [02+m0___6552_0_0]
                [040o5001+7016+70_victorious__34428_0_0]
                [+o0___1160_0_0]
                [+o0___1719_0_0]
                [+o0___23922_0_0]
                [00w+l0___2565_0_0]
                [0w+m0___6572_0_0]
                [+o0___6343_0_0]
                [002+l0___20243_0_0]
                [002+l0___57755_0_0]]=],
    -- ARMS WARRIOR
    [71] = [=[[02+m0___6552_0_0]
                [040o5001+80u+70_victorious__34428_0_0]
                [+o0___1719_0_0]
                [+o0___167105_0_0]
                [04wn4002+80k+70___163201_0_0]
                [040n1002+80k+70___12294_0_0]
                [00w+l0___1680_0_0]]=],
    -- FURY WARRIOR
    [72] = [=[[02+m0___6552_0_0]
                [+o0___1719_0_0]
                [04wn4002+80k+70___5308_0_0]
                [01w+l0_enrage__184367_0_0]
                [+701008+d0_battle cry__205545_0_0]
                [00w+l0___85288_0_0]
                [+o0___23881_0_0]
                [01+501+603+90_frenzy__100130_0_0]
                [+70150003+b0_frenzy__100130_0_0]
                [+o0___190411_0_0]]=],
    -- FROST DK
    [251] = [=[[02+m0___47528_0_0]
                [04wo5+a01q+70___49998_0_0]
                [0w+m0___49998_0_0]
                [0g+50220005+b0_razorice__190778_0_0]
                [04w72+a01b+70___49143_0_0]
                [00w+l0___196770_0_0]
                [0w+m0___49184_0_0]
                [0w+m0___49020_0_0]
                [00w61+b04+70___49020_0_0]
                [+o0___49143_0_0]]=],
    -- BLOOD DK
    [250] = [=[[02+m0___47528_0_0]
                [01w+401+603+90_bone shield__195182_0_0]
                [01+502+g0_blood plague__50842_0_0]
                [0w+m0___43265_0_0]
                [04w72+a01b+70___49998_0_0]
                [+70140006+b0_bone shield__195182_0_0]
                [+o0___205223_0_0]
                [00w+l0___206930_0_0]]=],
    -- UNHOLY DK
    [252] = [=[[02+m0___47528_0_0]
                [000m3+j0___46584_0_0]
                [04072+a01b+70___47541_0_0]
                [01+c03+90_virulent plague__77575_0_0]
                [00w+4013000k+b0_cold heart__45524_0_0]
                [0w+m0___47541_0_0]
                [+o0___63560_0_0]
                [+70250006+b0_festering wounds__85948_0_0]
                [+70220006+b0_festering wounds__220143_0_0]
                [00w+40220003+b0_festering wounds__55090_0_0]]=],
    -- PROT PALADIN
    [66] = [=[[02+m0___96231_0_0]
                [01+501+g0_consecration__26573_0_0]
                [+o0___31935_0_0]
                [+o0___20271_0_0]
                [+o0___53600_0_0]
                [+o0___26573_0_0]
                [+o0___53595_0_0]
                [+o0___184092_0_0]]=],
    -- RET PALADIN
    [70] = [=[[02+m0___96231_0_0]
                [00w+402+g0_judgment__85256_0_0]
                [000a4+b03+70___184575_0_0]
                [000a5+b05+70___35395_0_0]
                [+o0___20271_0_0]]=],
    -- HOLY PALADIN
    [65] = [=[[01+503+g0_beacon of light__53563_0_0]
                [00w+403+g0___20473_0_0]
                [040n5003+701A+70___223306_0_0]
                [040n5003+80p+70___19750_0_0]
                [040n5003+701q+70___82326_0_0]
                [+702+g0___20271_0_0]
                [+702+g0___114165_0_0]
                [+o0___85222_0_0]]=],
    -- VENG DH
    [581] = [=[[02+m0___183752_0_0]
                [+n04___207407_0_204021]
                [01+501+g0_demon spikes__203720_0_0]
                [000j2+b0O+70___228477_0_0]
                [000j4+a01g+70___232893_0_0]
                [+o0___211881_0_0]
                [+o0___204021_0_0]
                [+o0___178740_0_0]
                [+o0___204596_0_0]
                [+o0___189110_0_0]
                [00w+40150005+b0_soul fragments__209795_0_0]
                [00w+40110003+b0_soul fragments__247454_0_0]
                [000j4+a01q+70___203782_0_0]]=],
    -- HAVOC DH
    [577] = [=[[02+m0___183752_0_0]
                [0g+501+g0_metamorphosis__206491_0_0]
                [+o0___211053_0_0]
                [+o0___201467_0_0]
                [+901+a01000___195072_0_0]
                [0h+m0_metamorphosis__191427_0_0]
                [+o0___247938_0_0]
                [+o0___188499_0_0]
                [00w+l0___162794_0_0]
                [000i4+b0u+70___232893_0_0]
                [000i4+a016+70___162243_0_0]]=],
    -- ASSASSIN ROG
    [259] = [=[[02+m0___1766_0_0]
                [01+501+g0_deadly poison__2823_0_0]
                [01+501+g0_leeching poison__108211_0_0]
                [01+502+603+90_rupture__1943_0_0]
                [0g+m0___79140_0_0]
                [+o0___703_0_0]
                [00052+b04+70___32645_0_0]
                [+o0___192759_0_0]
                [+o0___245388_0_0]
                [+o0___1329_0_0]]=],
    -- OUTLAW ROG
    [260] = [=[[02+m0___1766_0_0]
                [+o0___13750_0_0]
                [01w+402+603+90_ghostly strike__196937_0_0]
                [0g+m0___202665_0_0]
                [0ww54+b04+70___185763_0_0]
                [00w52001500020004+70_roll the bones__193316_0_0]
                [01w52+90304+70_roll the bones__193316_0_0]
                [00w52+b05+70___2098_0_0]
                [00w55+b06+70___193315_0_0]]=],
    -- SUBTLETY ROG
    [261] = [=[[02+m0___1766_0_0]
                [01w+402+603+90_Nightblade__195452_0_0]
                [00w52+b05+70_Symbols of Death__152150_0_0]
                [00w52+b05+70___196819_0_0]
                [0g+l03___212283_0_185313]
                [+902+a010k4___185313_0_185313]
                [00w55+b05+70___185438_0_0]
                [0g054+b03+70___1856_0_0]
                [00w55+b05+70___53_0_0]]=],
    -- BREWMASTER MONK
    [268] = [=[[00w+l0___121253_0_0]
                [+o0___205523_0_0]
                [+o0___115181_0_0]
                [00042+a011+70___100780_0_0]]=],
    -- MISTWEAVER MONK
    [270] = [=[[040n4003+80u+70___116849_0_0]
                [0w+503+g0___116670_0_0]
                [01+503+g0_Enveloping Mist__124682_0_0]
                [+703+g0___115151_0_0]
                [+703+g0___116694_0_0]]=],
    -- WW MONK
    [269] = [=[[00w+l0___107428_0_0]
                [00w+l0___113656_0_0]
                [08wd542+9041q+50___100780_0_0]
                [00w+l0___100784_0_0]
                [00w+l0___100780_0_0]]=],
    -- FIRE MAGE
    [63] = [=[[+n03___116011_0_190319]
                [+o0___190319_0_0]
                [+902+a02000___116011_0_0]
                [0w+m0___11366_0_0]
                [+902+a03000___108853_0_0]
                [+701+g0_Heating Up__108853_0_0]
                [01+501+g0_Heating Up__133_0_0]]=],
    -- ARCANE MAGE
    [62] = [=[[+902+a02000___116011_0_0]
                [0g0h3+j0___205032_0_0]
                [010h2002+60404+70_Nether Tempest__114923_0_0]
                [000h2+b03+70___5143_0_0]
                [04015h2+801A04+50___5143_0_0]
                [04015+b0p+70___44425_0_0]
                [000h5+b04+70___30451_0_0]]=],
    -- FROST MAGE
    [64] = [=[[+702+g0_Winter's Chill__30455_0_0]
                [+701+g0_Fingers of Frost__30455_0_0]
                [+701+g0_Brain Freeze__44614_0_0]
                [+n03___116011_0_12472]
                [0g+m0___12472_0_0]
                [+902+a010a4___116011_0_116011]
                [+o0___55342_0_0]
                [+o0___157997_0_0]
                [+o0___116_0_0]]=],
    -- DISC PRIEST
    [256] = [=[[01+502+603+90_Shadow Word: Pain__589_0_0]
                [+702+g0___214621_0_0]
                [+o0___47540_0_0]
                [+o0___585_0_0]
                [01+503+g0_Atonement__194509_0_0]
                [+703+g0___17_0_0]
                [040n4003+701b+70___186263_0_0]
                [01+503+g0_Atonement__200829_0_0]]=],
    -- HOLY PRIEST
    [257] = [=[[0w+503+g0___2061_0_0]
                [+703+g0___33076_0_0]
                [040n4003+80u+70___2050_0_0]
                [040n5003+80O+70___2061_0_0]
                [040n2003+80O+70___2060_0_0]
                [+703+g0___139_0_0]]=],
    -- SHADOW PRIEST
    [258] = [=[[00w+402+g0___228260_0_0]
                [00w+40202+a02032___32379_0_8092]
                [+903+a01032___32379_0_8092]
                [+7012000k+b0_Voidform__200174_0_0]
                [01+502+603+90_Shadow Word: Pain__589_0_0]
                [01+502+603+90_Vampiric Touch__34914_0_0]
                [+702+g0___8092_0_0]
                [+702+g0___15407_0_0]]=],
    -- ELE SHAM
    [262] = [=[[5+602+g0___370_0_0]
                [a+603+g0___51886_0_0]
                [a+601+g0___51886_0_0]
                [01w+402+g0_Flame Shock__188389_0_0]
                [000c2+a01R+70___8042_0_0]
                [0ww+l0___51505_0_0]
                [00w+602+a02000___51505_0_0]
                [010c2002+6090k+70_Flame Shock__188389_0_0]
                [+o0___198067_0_0]
                [+o0___117014_0_0]
                [+o0___188196_0_0]]=],
    -- ENHANCE SHAM
    [263] = [=[[5+602+g0___370_0_0]
                [a+601+g0___51886_0_0]
                [a+603+g0___51886_0_0]
                [+m034___51533_0_187874]
                [00w+l0___187874_0_0]
                [00w+401+g0_Stormbringer__17364_0_0]
                [01+501+603+90_Flametongue__193796_0_0]
                [00w+l0___17364_0_0]
                [+o0___193786_0_0]
                [00wc1+b0E+70___60103_0_0]]=],
    -- RESTO SHAM
    [264] = [=[[01+503+g0_Riptide__61295_0_0]
                [+o0___5394_0_0]
                [+o0___73920_0_0]
                [+701+g0_Tidal Waves__8004_0_0]
                [+703+g0___77472_0_0]
                [+o0___1064_0_0]]=],
    -- BM HUNTER
    [253] = [=[[+o0___19574_0_0]
                [+o0___34026_0_0]
                [000m4+j0___982_0_0]
                [040m4+a01b+70___136_0_0]
                [+o0___120679_0_0]
                [00031+b0u+70___193455_0_0]]=],
    -- MARKS HUNTER
    [254] = [=[[02+m0___147362_0_0]
                [04w32+a01q+70___19434_0_0]
                [00w+402+g0_Vulnerable__19434_0_0]
                [01w+402+g0_Vulnerable__185901_0_0]
                [0w+m0___185358_0_0]
                [+o0___185358_0_0]]=],
    -- SURVIVAL HUNTER
    [255] = [=[[01w+4015000403+90_Way of the Mok'Nathal__186270_0_0]
                [00w+l0___202800_0_0]
                [01w+402+603+90_Lacerate__185855_0_0]
                [0g+m0___162488_0_0]
                [0g+m0___191433_0_0]
                [00w+l0___190928_0_0]
                [00w+l0___186270_0_0]]=],
    -- AFF LOCK
    [265] = [=[[04015+b0E+70___1454_0_0]
                [01+502+603+90_Agony__980_0_0]
                [01+502+603+90_Corruption__172_0_0]
                [01+502+603+90_Unstable Affliction__30108_0_0]
                [00082002+803+70_Unstable Affliction__30108_0_0]
                [+702+g0_Unstable Affliction__198590_0_0]]=],
    -- DEMO LOCK
    [266] = [=[[01+502+603+90_Doom__603_0_0]
                [04014+b0Y+70___1454_0_0]
                [00082+b04+70___105174_0_0]
                [00w+l0___104316_0_0]
                [+o0___18540_0_0]
                [+o0___193396_0_0]
                [+o0___686_0_0]]=],
    -- DESTRO LOCK
    [267] = [=[[01+502+603+90_Immolate__348_0_0]
                [+o0___1122_0_0]
                [00082+b05+70___116858_0_0]
                [+o0___18540_0_0]
                [+o0___17877_0_0]
                [00w+l0___116858_0_0]
                [+o0___29722_0_0]]=],
    -- BALANCE DRUID
    [102] = [=[[01+502+603+90_Moonfire__8921_0_0]
                [01+502+603+90_Sunfire__93402_0_0]
                [+701+g0_Solar Empowerment__190984_0_0]
                [+701+g0_Lunar Empowerment__194153_0_0]
                [00w+l0___78674_0_0]
                [+o0___190984_0_0]]=],
    -- FERAL DRUID
    [103] = [=[[01w+401+603+90_Savage Roar__52610_0_0]
                [00044+b0k+70___5217_0_0]
                [0ww+l0___106830_0_0]
                [01w+402+603+90_Rake__1822_0_0]
                [05wn1522+6030p05+50_Rip__1079_0_0]
                [08w52n42+8050p+50_Rip__22568_0_0]
                [00w52+b05+70___22568_0_0]
                [00w+l0___5221_0_0]]=],
    -- GUARDIAN DRUID
    [104] = [=[[02w+l0___106839_0_0]
                [00w+l0___33917_0_0]
                [0w+m0___8921_0_0]
                [00w+l0___77758_0_0]
                [01w+402+603+90_Moonfire__8921_0_0]
                [00w+l0___6807_0_0]
                [+o0___213771_0_0]]=],
    -- RESTO DRUID
    [105] = [=[[01+503+603+90_Efflorescence__145205_0_0]
                [01+503+604+90_Lifebloom__33763_0_0]
                [01+503+603+90_Rejuvenation__774_0_0]
                [040n4003+80u+70___18562_0_0]
                [+o0___48438_0_0]
                [+o0___8936_0_0]]=]
}

function ConditionerAddOn:ConvertFromMask(charSet, tab)
    local first, second = (#charSet < 2) and "0" or charSet:sub(1, 1),
        charSet:sub((#charSet < 2) and 1 or 2, (#charSet < 2) and 1 or 2)
    local firstDecimal, secondDecimal = ConditionerAddOn.BitMap[first], ConditionerAddOn.BitMap[second]
    local decimalMask = (64 * firstDecimal) + secondDecimal
    if (not tab) then
        return decimalMask
    end
    local results = {}
    for i = 1, ((#charSet < 2) and 6 or 12) do
        local bitValue = math.pow(2, i - 1)
        local answer = bit.band(decimalMask, bitValue)
        results[i] = (answer ~= 0) and true or false
    end
    return results
end

function ConditionerAddOn:EncodeToMask(results, toSingle)
    local sum = 0
    if (type(results) == "table") then
        for k, v in ipairs(results) do
            sum = sum + ((v) and math.pow(2, k - 1) or 0)
        end
    elseif (type(results) == "number") then
        sum = results
    else
        return
    end

    local firstCharVal, firstChar = math.floor(sum / 64), "0"
    local secondCharVal, secondChar = sum % 64, "0"
    for k, v in pairs(ConditionerAddOn.BitMap) do
        firstChar = (firstCharVal == v) and k or firstChar
        secondChar = (secondCharVal == v) and k or secondChar
    end

    if (toSingle) then
        return secondChar
    else
        return string.format("%s%s", firstChar, secondChar)
    end
end

function ConditionerAddOn:AddBorder(frame)
    frame.Border = frame.Border or CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    frame.Border:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.Border:SetBackdrop({
        edgeFile = "Interface\\GLUES\\COMMON\\Glue-Tooltip-Border",
        edgeSize = 16
    })
    frame.Border:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 4)
    frame.Border:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -8, -8)
    frame.Border:ApplyBackdrop()
end

function ConditionerAddOn:GetNextPriorityButton()
    for k, v in ipairs(ConditionerAddOn.PriorityButtons) do
        if (v.Data.spellID == 0 and v.Data.itemID == 0) then
            v:Show()
            return v, k
        end
    end
    local freeButton = ConditionerAddOn:NewPriorityButton()
    local myParent = (#ConditionerAddOn.PriorityButtons > 0) and
        ConditionerAddOn.PriorityButtons[#ConditionerAddOn.PriorityButtons] or
        ConditionerAddOn.MainButton
    freeButton:SetPoint("TOPRIGHT", myParent, "BOTTOMRIGHT")
    table.insert(ConditionerAddOn.PriorityButtons, freeButton)
    return freeButton, #ConditionerAddOn.PriorityButtons
end

function ConditionerAddOn:ScrollPriorityButtons(numToHide)
    numToHide = numToHide or 0
    local previous = ConditionerAddOn.MainButton
    for i, v in ipairs(ConditionerAddOn.PriorityButtons) do
        -- up to the num to hide we will attach those somewhere else
        v:ClearAllPoints()
        if (i <= numToHide) then
            v:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT")
        else
            v:SetPoint("TOPLEFT", previous, "BOTTOMLEFT")
            previous = v
        end
    end
end

function ConditionerAddOn:GetUsableResources()
    local usableResources = {}
    for k, v in pairs(Enum.PowerType) do
        if (v >= 0) and not (v == Enum.PowerType.NumPowerTypes) then
            local isUsable = UnitPowerMax("player", v)
            if (isUsable) and (isUsable > 0) then
                usableResources[v + 1] = true
            end
        end
    end
    return usableResources
end

function ConditionerAddOn:FixupSavedVariables()
    if (ConditionerAddOn_SavedVariables.Loadouts) and (#ConditionerAddOn_SavedVariables.Loadouts > 0) then
        local newIndexMap = {}
        for k, v in ipairs(ConditionerAddOn_SavedVariables.Loadouts) do
            table.insert(ConditionerAddOn_SavedVariables_Loadouts, v)
            newIndexMap[k] = #ConditionerAddOn_SavedVariables_Loadouts
        end
        for k, v in pairs(ConditionerAddOn_SavedVariables.CurrentLoadouts) do
            local newValue = newIndexMap[v]
            ConditionerAddOn_SavedVariables.CurrentLoadouts[k] = newValue
        end
        ConditionerAddOn_SavedVariables.Loadouts = nil
    end
end

function ConditionerAddOn.DebuffExists(unitToken, auraString, filter)
    for i = 1, 64 do
        local auraName, auraIcon, auraStacks, _, auraDuration, auraExpireTimestamp, _, auraIsStealable, _, auraSpellID,
        _, _, _, _, auraTimeMod = UnitDebuff(unitToken, i, filter)
        if (auraName) and ((auraName:lower() == auraString:lower()) or (auraSpellID == tonumber(auraString))) then
            return auraName, auraIcon, auraStacks, _, auraDuration, auraExpireTimestamp, _, auraIsStealable, _,
                auraSpellID, _, _, _, _, auraTimeMod
        end
    end
    return false
end

function ConditionerAddOn.BuffExists(unitToken, auraString, filter)
    for i = 1, 64 do
        local auraName, auraIcon, auraStacks, _, auraDuration, auraExpireTimestamp, _, auraIsStealable, _, auraSpellID,
        _, _, _, _, auraTimeMod = UnitBuff(unitToken, i, filter)
        if (auraName) and ((auraName:lower() == auraString:lower()) or (auraSpellID == tonumber(auraString))) then
            return auraName, auraIcon, auraStacks, _, auraDuration, auraExpireTimestamp, _, auraIsStealable, _,
                auraSpellID, _, _, _, _, auraTimeMod
        end
    end
    return false
end

function ConditionerAddOn:GetRunes()
    local maxRunes = UnitPowerMax("player", Enum.PowerType.Runes)
    local count = 0
    for i = 1, maxRunes do
        local _, _, isReady = GetRuneCooldown(i)
        count = count + ((isReady) and 1 or 0)
    end
    return count, maxRunes
end

function ConditionerAddOn:IsValidShapeshift(id)
    local _, _, classID = UnitClass("player")
    if (classID == 11) and (id == 1 or id == 2 or id == 3 or id == 4 or id == 5) then
        return true
    elseif (classID == 1) and (id == 8) then
        return true
    elseif (classID == 5) and (id == 7 or id == 6) then
        return true
    elseif (classID == 4) and (id == 9) then
        return true
    elseif (id == 0 or id == 10) then
        return true
    elseif (id > 10 and ConditionerAddOn.Enums.shapeShiftChoicesEnum[id] ~= "") then
        return true
    else
        return false
    end
end

function ConditionerAddOn:CollapsePriorityButtons()
    local collapsedData = {}
    for k, v in ipairs(ConditionerAddOn.PriorityButtons) do
        if (v.Data.spellID == 0) and (v.Data.itemID == 0) then
            -- it's empty
        else
            table.insert(collapsedData, v)
        end
    end

    for k, v in ipairs(ConditionerAddOn.PriorityButtons) do
        if (k <= #collapsedData) then
            local collapsedConditions = ConditionerAddOn:GetConditions(collapsedData[k])
            ConditionerAddOn:SetConditions(v, collapsedConditions)
            v:UpdateTexture()
        else
            ConditionerAddOn:SetConditions(v)
            v:Hide()
        end
    end
end

function ConditionerAddOn:IsEliteOrHigher(token)
    if (not UnitExists(token)) then
        return false
    end

    local classification = UnitClassification(token)
    if (classification == "normal" or classification == "trivial" or classification == "minus") then
        return false
    end

    return true
end

function ConditionerAddOn:CreateSwingFrame(text, parent, r, g, b)
    local o = CreateFrame("Frame", nil, parent)
    o:SetFrameStrata("MEDIUM")
    o.Texture = o:CreateTexture()
    o.Texture:SetAllPoints(o)
    o.Texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
    -- o.Texture:SetGradient("HORIZONTAL", CreateColor(r * 0.25, g * 0.25, b * 0.25), CreateColor(r, g, b))
    o.Texture:SetColorTexture(r, g, b)
    o.Text = o:CreateFontString(nil, "OVERLAY", "SystemFont_NamePlateCastBar")
    o.Text:SetPoint("LEFT", o, "LEFT")
    o.Text:SetText(text)

    o.Slot = CreateFrame("Frame", nil, o)
    o.Slot:SetSize(1, 1)
    o.Slot:SetPoint("TOPRIGHT", o, "TOPLEFT")
    o.Slot:SetPoint("BOTTOMRIGHT", o, "BOTTOMLEFT")
    o.Slot.Icon = o.Slot:CreateTexture()
    o.Slot.Icon:SetAllPoints(o.Slot)

    o.Background = CreateFrame("Frame", nil, o)
    o.Background:SetFrameLevel(1)
    o.Background:SetPoint("TOPLEFT", o, "TOPRIGHT")
    o.Background:SetPoint("BOTTOMLEFT", o, "BOTTOMRIGHT")
    o.Background.Texture = o.Background:CreateTexture()
    o.Background.Texture:SetAllPoints(o.Background)
    o.Background.Texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
    o.Background.Texture:SetColorTexture(0, 0, 0, 0.5)
    -- o.Background.Texture:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0.25, r * 0.5, g * 0.5, b * 0.4, 0.4)
    return o
end

function ConditionerAddOn:UpdateCastBar(elapsed)
    if (ConditionerAddOn_SavedVariables.Options.ShowTargetCastBar or ConditionerAddOn.ShowCastBar) and
        (not UnitHasVehicleUI("player")) then
        if (ConditionerAddOn.TrackedFrameDragAnchor.CastingBar) and (ConditionerAddOn.TrackingFrames) and
            (ConditionerAddOn.TrackingFrames[1]) and (ConditionerAddOn.TrackingFrames[1]:IsShown()) then
            local mainTrackedFrame = ConditionerAddOn.TrackingFrames[1]
            ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:SetHeight(mainTrackedFrame:GetHeight() / 6)
            ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Text:SetFont("Fonts\\FRIZQT__.TTF", math.ceil(
                0.5 * mainTrackedFrame:GetHeight() / 5), "OUTLINE, NORMAL")
            local castSpellName, _, castSpellTexture, castStart, castEnd, _, _, uninterruptable, castSpellID =
                ConditionerUnitCastingInfo("target")
            local channelSpellName, _, channelSpellTexture, channelStart, channelEnd, _, notInterruptible,
            channelSpellID = ConditionerUnitChannelInfo("target")
            local texture = castSpellTexture or channelSpellTexture
            local castName = castSpellName or channelSpellName
            local timeLeft = castEnd or channelEnd
            local startTime = castStart or channelStart
            local greyBar = uninterruptable or notInterruptible
            if (texture) then
                ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Slot.Icon:SetTexture(texture)
                ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Slot:SetWidth(
                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:GetHeight())
                ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Text:SetText(castName)
                if (greyBar) then
                    --     ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Texture:SetGradient(
                    --         "HORIZONTAL", CreateColor(0.75, 0.75, 0.75), CreateColor(1, 1, 1)
                    --     )
                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Texture:SetColorTexture(0.75, 0.75, 0.75)
                else
                    --     ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Texture:SetGradient(
                    --         "HORIZONTAL", CreateColor(0.5, 0.5, 0), CreateColor(1, 1, 0)
                    --     )
                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Texture:SetColorTexture(1, 1, 0)
                end
                local mult = (timeLeft - GetTime() * 1000) / (timeLeft - startTime)
                if (castSpellName) then
                    mult = 1 - mult
                end
                ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:SetWidth(math.min(mult * mainTrackedFrame:GetWidth(),
                    mainTrackedFrame:GetWidth()))
                ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Background:SetWidth(mainTrackedFrame:GetWidth() -
                    ConditionerAddOn.TrackedFrameDragAnchor
                    .CastingBar:GetWidth())

                if (ConditionerAddOn.ShowCastBar) then
                    local convertedTime = ConditionerAddOn:ConvertTime(timeLeft / 1000 - GetTime())
                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Timer:ClearAllPoints()
                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Timer:SetPoint("CENTER", mainTrackedFrame,
                        "CENTER")
                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Timer:SetText(convertedTime)
                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Timer:SetFont("Fonts\\FRIZQT__.TTF", math.ceil(
                        mainTrackedFrame:GetHeight() / 3), "OUTLINE, NORMAL")
                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Timer:SetTextColor(mult, 1 - mult, 0)
                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Timer:Show()
                else
                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Timer:Hide()
                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Timer:SetText("")
                end

                ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:Show()
            else
                ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:Hide()
                ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Background:SetWidth(mainTrackedFrame:GetWidth() -
                    ConditionerAddOn.TrackedFrameDragAnchor
                    .CastingBar:GetWidth())
                ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:SetWidth(mainTrackedFrame:GetWidth())
            end
        else
            ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:Hide()
        end
    else
        ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:Hide()
    end
end

function ConditionerAddOn:ConvertTime(seconds)
    local s, m, h = seconds, math.floor(seconds / 60), math.floor(seconds / 3600)
    local finalTimeString = (seconds <= 9.9) and string.format("%.1f", seconds) or string.format("%.0f", seconds)
    if (m > 0) then
        finalTimeString = string.format("%sm", m)
    end
    if (h > 0) then
        finalTimeString = string.format("%sh", h)
    end
    return finalTimeString
end

function ConditionerAddOn:OnUpdate(elapsed)
    ConditionerAddOn:ClearTrackers()
    if (ConditionerAddOn_SavedVariables.Options.OnlyDisplayInCombat) and (not SpellBookFrame:IsShown()) and
        (not UnitAffectingCombat("player")) or (UnitHasVehicleUI("player")) then
        ConditionerAddOn:HideTrackerPool(ConditionerAddOn.MouseIconTracker.Pool)
        ConditionerAddOn:HideTrackerPool(ConditionerAddOn.AoeRotation.Pool)
        return
    end
    local sortedList = ConditionerAddOn:GetCooldownList()
    ConditionerAddOn_SavedVariables.Options.Opacity = ConditionerAddOn_SavedVariables.Options.Opacity or 100
    ConditionerAddOn_SavedVariables.Options.NumTrackedFrames =
        ConditionerAddOn_SavedVariables.Options.NumTrackedFrames or 5

    -- mouse icon, find first mouseover
    local usingMouseover = ConditionerAddOn_SavedVariables.Options.ShowMouseoverAtCursor
    if (usingMouseover) then
        ConditionerAddOn:CollectMouseOverSpells(sortedList)
    else
        ConditionerAddOn:HideTrackerPool(ConditionerAddOn.MouseIconTracker.Pool)
    end

    -- for AoE rotation
    local usingAoE = ConditionerAddOn_SavedVariables.Options.ShowAoeRotation
    if (usingAoE) then
        ConditionerAddOn:CollectAoeSpells(sortedList)
    else
        ConditionerAddOn:HideTrackerPool(ConditionerAddOn.AoeRotation.Pool)
    end

    local numTracked = 0
    for k, v in ipairs(sortedList) do
        if (numTracked < ConditionerAddOn_SavedVariables.Options.NumTrackedFrames) then
            if ((not usingMouseover) or (usingMouseover and not v.isMouseover)) and
                ((not usingAoE) or (usingAoE and not v.isAoe)) then
                numTracked = numTracked + 1
                local newTrackerFrame = ConditionerAddOn:GetAvailableTrackingFrame()
                local swingFrameHeight = newTrackerFrame:GetHeight() / 6
                if (numTracked == 1) and (ConditionerAddOn.TrackedFrameDragAnchor.MainHand) then
                    ConditionerAddOn.TrackedFrameDragAnchor.MainHand:SetHeight(swingFrameHeight)
                    ConditionerAddOn.TrackedFrameDragAnchor.OffHand:SetHeight(swingFrameHeight)
                    ConditionerAddOn.TrackedFrameDragAnchor.Ranged:SetHeight(swingFrameHeight)
                    ConditionerAddOn.TrackedFrameDragAnchor.MainHand:ClearAllPoints()
                    local MH_shown = ConditionerAddOn.TrackedFrameDragAnchor.MainHand:IsShown() and 1 or 0
                    local OH_shown = ConditionerAddOn.TrackedFrameDragAnchor.OffHand:IsShown() and 1 or 0
                    local RH_shown = ConditionerAddOn.TrackedFrameDragAnchor.Ranged:IsShown() and 1 or 0
                    local castBarShown = ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:IsShown() and 1 or 0

                    ConditionerAddOn.TrackedFrameDragAnchor.Ranged:SetPoint("TOPLEFT",
                        ConditionerAddOn.TrackedFrameDragAnchor.OffHand,
                        "BOTTOMLEFT", 0, swingFrameHeight * (1 - OH_shown))

                    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:ClearAllPoints()
                    if (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 3) then
                        ConditionerAddOn.TrackedFrameDragAnchor.MainHand:SetPoint("BOTTOMLEFT", newTrackerFrame,
                            "TOPLEFT", 0, swingFrameHeight * (castBarShown + OH_shown + RH_shown))
                        ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:SetPoint("BOTTOMLEFT",
                            newTrackerFrame, "TOPLEFT")
                    elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 0 or
                            ConditionerAddOn_SavedVariables.Options.AnchorDirection == 2) then
                        ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:SetPoint("BOTTOMLEFT", newTrackerFrame,
                            "TOPLEFT")
                        ConditionerAddOn.TrackedFrameDragAnchor.MainHand:SetPoint("TOPLEFT", newTrackerFrame,
                            "BOTTOMLEFT")
                    else
                        ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:SetPoint("TOPLEFT", newTrackerFrame,
                            "BOTTOMLEFT")
                        ConditionerAddOn.TrackedFrameDragAnchor.MainHand:SetPoint("TOPLEFT",
                            newTrackerFrame, "BOTTOMLEFT", 0, -swingFrameHeight * castBarShown)
                    end

                    ConditionerAddOn.ShowCastBar = ConditionerAddOn.PriorityButtons[v.priority].Conditions
                        .isInterruptBool
                end
                -- handle duration logic
                local auraTexture, auraTime, auraTS = v.auraIcon, v.auraTime, v.auraTS
                if (auraTime) then
                    newTrackerFrame.Countdown.Icon:SetPoint("TOPRIGHT", newTrackerFrame, "TOPRIGHT")
                    newTrackerFrame.Countdown.Text:SetPoint("TOPLEFT", newTrackerFrame, "TOPLEFT")
                    local newHeight = newTrackerFrame.Countdown.Icon:GetHeight()
                    local auraDelta = (auraTime > 0) and math.max((auraTS - GetTime()) / auraTime, 0) or 0
                    local textTime = math.max(auraTS - GetTime(), 0)
                    newTrackerFrame.Countdown:SetHeight(newHeight * (1 - auraDelta))
                    newTrackerFrame.Countdown.Icon:SetTexture(auraTexture)
                    newTrackerFrame.Countdown.Icon:SetTexCoord(cropAmount, 1 - cropAmount, cropAmount, 1 - cropAmount)
                    newTrackerFrame.Countdown.Text:SetText((textTime > 0) and
                        string.format("%s",
                            ConditionerAddOn:ConvertTime(textTime)) or "")
                    newTrackerFrame.Countdown.Text:SetTextColor(1 - auraDelta, auraDelta, 0)
                    newTrackerFrame.Countdown:Show()
                else
                    newTrackerFrame.Countdown:Hide()
                end
                local keybind = ConditionerAddOn.PriorityButtons[v.priority].Conditions.keyBindingString
                local isCoolingDown, cooldownDuration = newTrackerFrame.cooldown:GetCooldownTimes()
                if (cooldownDuration ~= v.duration) then
                    newTrackerFrame.cooldown:SetCooldown(v.startTime, v.duration)
                end
                local prioSlotButton = ConditionerAddOn.PriorityButtons[v.priority]
                local prioTexture = v.texture
                if (prioSlotButton.Data.itemID == 0) then
                    local hasBookSlot = FindSpellBookSlotBySpellID(prioSlotButton.Data.spellID)
                    if (hasBookSlot) then
                        prioTexture = GetSpellBookItemTexture(hasBookSlot, "spell")
                    else
                        local tryPetSlot = FindSpellBookSlotBySpellID(prioSlotButton.Data.spellID, "pet")
                        if (tryPetSlot) then
                            prioTexture = GetSpellBookItemTexture(tryPetSlot, "pet")
                        end
                    end
                end
                newTrackerFrame.Icon:SetTexture(prioTexture)
                newTrackerFrame.Icon:SetTexCoord(cropAmount, 1 - cropAmount, cropAmount, 1 - cropAmount)
                newTrackerFrame.Icon:SetAlpha(ConditionerAddOn_SavedVariables.Options.Opacity / 100)
                newTrackerFrame.Keybind:SetText(keybind)
                if (not v.range) or (v.range == 1) then
                    newTrackerFrame.Icon:SetDesaturated(false)
                    newTrackerFrame.Keybind:SetTextColor(0, 1, 1, 1)
                else
                    newTrackerFrame.Icon:SetDesaturated(true)
                    newTrackerFrame.Keybind:SetTextColor(1, 0.3, 0.75, 1)
                end

                newTrackerFrame.isActive = true
                newTrackerFrame:Show()
            end
        end
    end
end

function ConditionerAddOn:UpdateSwingTimers(elapsed)
    local parent = ConditionerAddOn.TrackingFrames[1]
    if (not parent) or (not parent:IsShown()) then
        ConditionerAddOn.TrackedFrameDragAnchor.MainHand:Hide()
        ConditionerAddOn.TrackedFrameDragAnchor.OffHand:Hide()
        ConditionerAddOn.TrackedFrameDragAnchor.Ranged:Hide()
        ConditionerAddOn.TrackedFrameDragAnchor.RangedCast:Hide()
        ConditionerAddOn.TrackedFrameDragAnchor.MainHand:SetWidth(100)
        ConditionerAddOn.TrackedFrameDragAnchor.OffHand:SetWidth(100)
        ConditionerAddOn.TrackedFrameDragAnchor.Ranged:SetWidth(100)
        ConditionerAddOn.TrackedFrameDragAnchor.RangedCast:SetWidth(100)
        return
    end
    if (UnitHasVehicleUI("player")) or (InCinematic()) or
        ((ConditionerAddOn_SavedVariables.Options.OnlyDisplayInCombat) and (not SpellBookFrame:IsShown()) and
            (not UnitAffectingCombat("player"))) then
        ConditionerAddOn:HideTrackerPool(ConditionerAddOn.MouseIconTracker.Pool)
        ConditionerAddOn:HideTrackerPool(ConditionerAddOn.AoeRotation.Pool)
        return
    end
    if (ConditionerAddOn_SavedVariables.Options.ShowSwingTimers) then
        if (ConditionerAddOn.TrackedFrameDragAnchor.MainHand) then
            local MH, OH = UnitAttackSpeed("player")
            local RH, _ = UnitRangedDamage and UnitRangedDamage("player") or nil, nil
            local rangedHaste = GetRangedHaste and GetRangedHaste() or 0
            local shotTimer = 0.5 * (1 / (1 + rangedHaste / 100))
            local w, h = parent:GetWidth(), parent:GetHeight() / 6
            ConditionerAddOn.TrackedFrameDragAnchor.MainHand.Text:SetFont("Fonts\\FRIZQT__.TTF", math.ceil(0.6 * h),
                "OUTLINE, NORMAL")
            ConditionerAddOn.TrackedFrameDragAnchor.OffHand.Text:SetFont("Fonts\\FRIZQT__.TTF", math.ceil(0.6 * h),
                "OUTLINE, NORMAL")
            if (MH) then
                local transmogSlot = ConditionerTransmogUtil.GetTransmogLocation("MAINHANDSLOT",
                    Enum.TransmogType.Appearance,
                    Enum.TransmogModification.Main)
                local _, _, _, _, _, _, _, textureId = ConditionerTransmog.GetSlotInfo(transmogSlot)
                textureId = textureId or GetInventoryItemTexture("player", INVSLOT_MAINHAND or 16)
                local progress = w * elapsed / MH
                local newWidth = ConditionerAddOn.TrackedFrameDragAnchor.MainHand:GetWidth() + progress
                ConditionerAddOn.TrackedFrameDragAnchor.MainHand:SetSize((newWidth >= w) and w or newWidth, h)
                ConditionerAddOn.TrackedFrameDragAnchor.MainHand.Background:SetWidth(w - newWidth)
                ConditionerAddOn.TrackedFrameDragAnchor.MainHand.Slot:SetWidth(
                    ConditionerAddOn.TrackedFrameDragAnchor.MainHand.Slot.Icon:GetHeight())
                ConditionerAddOn.TrackedFrameDragAnchor.MainHand.Slot.Icon:SetTexture(textureId)
                ConditionerAddOn.TrackedFrameDragAnchor.MainHand:Show()
            else
                ConditionerAddOn.TrackedFrameDragAnchor.MainHand:Hide()
            end

            if (OH) then
                local transmogSlotOH = ConditionerTransmogUtil.GetTransmogLocation("SECONDARYHANDSLOT",
                    Enum.TransmogType.Appearance, Enum.TransmogModification.Main)
                local _, _, _, _, _, _, _, textureIdOH = ConditionerTransmog.GetSlotInfo(transmogSlotOH)
                textureIdOH = textureIdOH or GetInventoryItemTexture("player", INVSLOT_OFFHAND or 17)
                local progressOH = w * elapsed / OH
                local newWidthOH = ConditionerAddOn.TrackedFrameDragAnchor.OffHand:GetWidth() + progressOH
                ConditionerAddOn.TrackedFrameDragAnchor.OffHand:SetSize((newWidthOH >= w) and w or newWidthOH, h)
                ConditionerAddOn.TrackedFrameDragAnchor.OffHand.Background:SetWidth(w - newWidthOH)
                ConditionerAddOn.TrackedFrameDragAnchor.OffHand.Slot:SetWidth(
                    ConditionerAddOn.TrackedFrameDragAnchor.OffHand.Slot.Icon:GetHeight())
                ConditionerAddOn.TrackedFrameDragAnchor.OffHand.Slot.Icon:SetTexture(textureIdOH)
                ConditionerAddOn.TrackedFrameDragAnchor.OffHand:Show()
            else
                ConditionerAddOn.TrackedFrameDragAnchor.OffHand:Hide()
            end

            if (RH and RH > 0 and not ConditionerAddOn_SavedVariables.Options.HideRangedSwingTimer) then
                local transmogSlotRH = ConditionerTransmogUtil.GetTransmogLocation("RANGEDSLOT",
                    Enum.TransmogType.Appearance, Enum.TransmogModification.Main)
                local _, _, _, _, _, _, _, textureIdRH = ConditionerTransmog.GetSlotInfo(transmogSlotRH)
                textureIdRH = textureIdRH or GetInventoryItemTexture("player", INVSLOT_RANGED or 18)
                local progressRH = w * elapsed / (RH - shotTimer)
                local newWidthRH = ConditionerAddOn.TrackedFrameDragAnchor.Ranged:GetWidth() + progressRH

                if ((IsCurrentSpell(75) or IsCurrentSpell(7918) or IsCurrentSpell(7919)) and newWidthRH >= w) then
                    -- add to the shot timer
                    local shotProgress = w * elapsed / shotTimer
                    local newShotWidth = ConditionerAddOn.TrackedFrameDragAnchor.RangedCast:GetWidth() + shotProgress
                    ConditionerAddOn.TrackedFrameDragAnchor.RangedCast:SetWidth((newShotWidth >= w) and w or newShotWidth)
                else
                    ConditionerAddOn.TrackedFrameDragAnchor.RangedCast:SetWidth(0.1)
                end
                ConditionerAddOn.TrackedFrameDragAnchor.Ranged:SetSize((newWidthRH >= w) and w or newWidthRH, h)
                ConditionerAddOn.TrackedFrameDragAnchor.Ranged.Background:SetWidth(w - newWidthRH)
                ConditionerAddOn.TrackedFrameDragAnchor.Ranged.Slot:SetWidth(
                    ConditionerAddOn.TrackedFrameDragAnchor.Ranged.Slot.Icon:GetHeight())
                ConditionerAddOn.TrackedFrameDragAnchor.Ranged.Slot.Icon:SetTexture(textureIdRH)
                ConditionerAddOn.TrackedFrameDragAnchor.Ranged:Show()
                ConditionerAddOn.TrackedFrameDragAnchor.RangedCast:Show()
            else
                ConditionerAddOn.TrackedFrameDragAnchor.Ranged:Hide()
                ConditionerAddOn.TrackedFrameDragAnchor.RangedCast:Hide()
            end
        end
    else
        ConditionerAddOn.TrackedFrameDragAnchor.MainHand:Hide()
        ConditionerAddOn.TrackedFrameDragAnchor.OffHand:Hide()
    end
end

function ConditionerAddOn:HandleSwingTimerRanged(...)
    -- local autoShotSpellID = 75
    if (select(1, ...) == "player") and ((select(3, ...) == 75) or (select(3, ...) == 7918) or (select(3, ...) == 7919)) and (ConditionerAddOn.TrackedFrameDragAnchor.Ranged) then
        ConditionerAddOn.TrackedFrameDragAnchor.Ranged:SetWidth(0.1)
        ConditionerAddOn.TrackedFrameDragAnchor.RangedCast:SetWidth(0.1)
    end
end

function ConditionerAddOn:HandleSwingTimerMelee(...)
    if (ConditionerAddOn.TrackedFrameDragAnchor.MainHand) then
        local eventArgs = { ... }
        if (CombatLogGetCurrentEventInfo) then
            eventArgs = { CombatLogGetCurrentEventInfo() }
        end
        local subEvent = eventArgs[2]
        local attacker = eventArgs[5]
        if (attacker == UnitName("player")) then
            if (subEvent == "SWING_DAMAGE") then
                if (eventArgs[21]) then
                    ConditionerAddOn.TrackedFrameDragAnchor.OffHand:SetWidth(0)
                else
                    ConditionerAddOn.TrackedFrameDragAnchor.MainHand:SetWidth(0)
                end
            elseif (subEvent == "SWING_MISSED") then
                if (eventArgs[13]) then
                    ConditionerAddOn.TrackedFrameDragAnchor.OffHand:SetWidth(0)
                else
                    ConditionerAddOn.TrackedFrameDragAnchor.MainHand:SetWidth(0)
                end
            end
        end
    end
end

function ConditionerAddOn:SpellCacheWatcher(...)
    local eventArgs = { ... }
    if (CombatLogGetCurrentEventInfo) then
        eventArgs = { CombatLogGetCurrentEventInfo() }
    end
    local subEvent = eventArgs[2]
    if (subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REMOVED") then
        ConditionerAddOn:SpellCacheInsert(eventArgs[13], 1, ConditionerAddOn.SpellCache)
    end
end

function ConditionerAddOn:CacheCurrentSpecSpells()
    local lastTab = GetNumSpellTabs()
    local _, _, s, e = GetSpellTabInfo(lastTab)
    local maxSlots = s + e
    for i = 1, maxSlots do
        local spellName = GetSpellBookItemName(i, "spell")
        if (spellName) then
            ConditionerAddOn:SpellCacheInsert(spellName, 1, ConditionerAddOn.SpellCache)
        end
    end
end

function ConditionerAddOn:TooltipScrubber()
    GameTooltip:HookScript("OnShow", function(self)
        local spellName = self:GetSpell()
        if (spellName) then
            ConditionerAddOn:SpellCacheInsert(spellName, 1, ConditionerAddOn.SpellCache)
        end
    end)
end

function ConditionerAddOn:SpellCacheInsert(word, i, node)
    if (i <= #word) then
        local char = word:sub(i, i)
        local index = string.byte(char:lower())
        node.children = node.children or {}
        if (index) then
            node.children[index] = node.children[index] or {
                value = char
            }
            ConditionerAddOn:SpellCacheInsert(word, i + 1, node.children[index])
        end
    else
        node.isComplete = true
    end
end

function ConditionerAddOn:SpellCacheTraverse(prefix, i, node, properPrefix)
    if (i <= #prefix) then
        local char = prefix:sub(i, i)
        properPrefix = properPrefix or ""
        local index = string.byte(char:lower())
        if (node.children) and (index) then
            local child = node.children[index]
            if (child) then
                return ConditionerAddOn:SpellCacheTraverse(prefix, i + 1, child,
                    string.format("%s%s", properPrefix, child.value))
            else
                return
            end
        else
            return
        end
    else
        return node, properPrefix
    end
end

function ConditionerAddOn:SpellCacheGetSuffixes(node, word, results)
    if (not node) then
        return
    end
    word = word or ""
    if (node.children) then
        for k, v in pairs(node.children) do
            ConditionerAddOn:SpellCacheGetSuffixes(v, string.format("%s%s", word, v.value), results)
        end
    end
    if (node.isComplete) then
        results:GetResultButton(word)
    end
end

function ConditionerAddOn:Delete(destFrame, pickup)
    if (destFrame.Data) then
        local tempSpellID, tempItemID = destFrame.Data.spellID, destFrame.Data.itemID
        ConditionerAddOn.TempConditions = ConditionerAddOn:GetConditions(destFrame)
        ConditionerAddOn:SetConditions(destFrame)
        ConditionerAddOn:CollapsePriorityButtons()
        if (pickup) then
            if (tempItemID ~= 0) then
                PickupItem(tempItemID)
            else
                -- so there's a bug with spell overrides, this is the workaround (kind of)
                local isKnown = IsSpellKnown(tempSpellID)
                if (not isKnown) then
                    -- it might be an override
                    local spellBookSlot = FindSpellBookSlotBySpellID(tempSpellID)
                    if (spellBookSlot) then
                        -- print("Probably picked up an override spell")
                        -- it IS there, what's the REAL ID?
                        local bookType, overrideSpellID = GetSpellBookItemInfo(spellBookSlot, "spell")
                        tempSpellID = overrideSpellID or tempSpellID
                    else
                        -- print("Probably tried to pick up an override spell that isn't active anymore")
                        -- if it ISN'T in your spellbook, you might have lost it somehow (changing OUT of Bear Form)
                        local overrideSpellName = GetSpellInfo(tempSpellID)
                        local _, _, _, _, _, _, baseSpellID = GetSpellInfo(overrideSpellName)
                        tempSpellID = baseSpellID or tempSpellID
                    end
                end
                local numPetSpells, _ = HasPetSpells()
                local isPetSpell = false

                if (numPetSpells) then
                    for i = 1, numPetSpells do
                        local petSpellName, petSpellType, petSpellID = GetSpellBookItemName(i, "pet")
                        if (petSpellID) and (petSpellID == tempSpellID) then
                            isPetSpell = i
                            break
                        end
                    end
                end

                if (isPetSpell) then
                    PickupSpellBookItem(isPetSpell, "pet")
                else
                    PickupSpell(tempSpellID)
                end
            end
        else
            ConditionerAddOn.TempConditions = nil
        end
        ConditionerAddOn:StoreCurrentLoadout()
        if (ConditionerAddOn.CurrentPriorityButton) then
            -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
        end
    end
end

function ConditionerAddOn:Place(destFrame)
    if (destFrame) then
        local newSpellID, newItemID = ConditionerAddOn:GetCursorInfo()
        if (destFrame.Conditions) then
            local lastAvailableFrame, lastAvailableFrameIndex = ConditionerAddOn:GetNextPriorityButton()
            for i = lastAvailableFrameIndex, 1, -1 do
                local prevFrame = ConditionerAddOn.PriorityButtons[i - 1]
                local thisFrame = ConditionerAddOn.PriorityButtons[i]
                local prevConditions = ConditionerAddOn:GetConditions(prevFrame)
                ConditionerAddOn:SetConditions(thisFrame, prevConditions)
                if (prevFrame == destFrame) then
                    ConditionerAddOn:SetConditions(destFrame, ConditionerAddOn.TempConditions, newSpellID, newItemID)
                    break
                end
            end
        else
            local newDestFrame = ConditionerAddOn:GetNextPriorityButton()
            ConditionerAddOn:SetConditions(newDestFrame, ConditionerAddOn.TempConditions, newSpellID, newItemID)
        end
        ConditionerAddOn.TempConditions = nil
        ClearCursor()
        ConditionerAddOn:StoreCurrentLoadout()
        if (ConditionerAddOn.CurrentPriorityButton) then
            -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
        end
    end
end

function ConditionerAddOn:SubEncode(loadString, shouldDecode)
    if (shouldDecode) then
        local firstHalf, secondHalf = loadString:match("(%[.-)(_.-%])")
        local decodedString = firstHalf:gsub("%+(.)(.)", function(a, b)
            local decoded_A = ConditionerAddOn:ConvertFromMask(a)
            local returnString = ""
            for i = 1, decoded_A do
                returnString = string.format("%s%s", returnString, b)
            end
            return returnString
        end)
        -- did we extend the number of conditions? fixup
        local _, numConditionsForSecondHalf = secondHalf:gsub("_", "_")
        if (numConditionsForSecondHalf ~= ConditionerAddOn.NumConditionsForSecondHalf) then
            -- we need to fix the string and add another
            local difference = ConditionerAddOn.NumConditionsForSecondHalf - numConditionsForSecondHalf
            if (difference > 0) then
                local underscoreDifference = string.rep("_", difference)
                secondHalf = secondHalf:gsub("]", underscoreDifference .. "]")
            end
        end

        decodedString = string.format("%s%s", decodedString, secondHalf)
        local decodeTest, decodeTestSuffix = decodedString:match(ConditionerAddOn.DecodePattern)
        -- print(decodeTest, decodeTestSuffix) -- DEBUG
        if (decodeTest) and (decodeTestSuffix) and (#decodeTest == ConditionerAddOn.Size) then
            return decodedString
        else
            return
        end
    else
        local encodableString, suffixData = loadString:match(ConditionerAddOn.DecodePattern)
        local subEncodedString = ""
        local count = 0
        local finalString = ""
        for i = 1, #encodableString do
            local lastLetter = encodableString:sub(i - 1, i - 1)
            local currLetter = encodableString:sub(i, i)
            if (lastLetter == currLetter) then
                finalString = finalString .. currLetter
                count = count + 1
                if (i == #encodableString) then
                    if (count > 3) then
                        local converted = ConditionerAddOn:EncodeToMask(count, true)
                        subEncodedString = string.format("%s+%s%s", subEncodedString, converted, lastLetter)
                    else
                        subEncodedString = string.format("%s%s", subEncodedString, finalString)
                    end
                end
            else
                if (count > 3) then
                    local converted = ConditionerAddOn:EncodeToMask(count, true)
                    subEncodedString = string.format("%s+%s%s", subEncodedString, converted, lastLetter)
                else
                    subEncodedString = string.format("%s%s", subEncodedString, finalString)
                end
                finalString = currLetter
                count = 1
                if (i == #encodableString) then
                    subEncodedString = string.format("%s%s", subEncodedString, currLetter)
                end
            end
        end
        subEncodedString = string.format("[%s%s", subEncodedString, suffixData)
        return subEncodedString
    end
end

function ConditionerAddOn:GetConditions(frame, withoutKeybinds)
    if (not frame.Conditions) then
        return false
    end
    local boolString = ConditionerAddOn:EncodeToMask({ frame.Conditions.secondsRemainingBool,
        frame.Conditions.isInterruptBool,
        frame.Conditions.resourceUsePercentageBool,
        frame.Conditions.alternateResourceUsePercentageBool,
        frame.Conditions.onlyWhenReadyBool,
        frame.Conditions.highlightOnlyBool, frame.Conditions.buffBool,
        frame.Conditions.debuffBool, frame.Conditions.magicBool,
        frame.Conditions.curseBool, frame.Conditions.poisonBool,
        frame.Conditions.diseaseBool })
    local boolStringShort = ConditionerAddOn:EncodeToMask({ frame.Conditions.cooldownRemainingIsItemID,
        frame.Conditions.onlyInRange, frame.Conditions.onlyDuringCC,
        frame.Conditions.showInAoeRotation, -- 4
        frame.Conditions.hideWhileCasting,  -- 5
        frame.Conditions.canCast }, true)
    local encoded_resourceTypeEnum = ConditionerAddOn:EncodeToMask(frame.Conditions.resourceTypeEnum, true)
    local encoded_resourceConditionalEnum =
        ConditionerAddOn:EncodeToMask(frame.Conditions.resourceConditionalEnum, true)
    local encoded_alternateResourceTypeEnum = ConditionerAddOn:EncodeToMask(frame.Conditions.alternateResourceTypeEnum,
        true)
    local encoded_alternateResourceConditionalEnum = ConditionerAddOn:EncodeToMask(frame.Conditions
        .alternateResourceConditionalEnum,
        true)
    local encoded_auraTargetEnum = ConditionerAddOn:EncodeToMask(frame.Conditions.auraTargetEnum, true)
    local encoded_stackConditionalEnum = ConditionerAddOn:EncodeToMask(frame.Conditions.stackConditionalEnum, true)
    local encoded_chargesConditionalEnum = ConditionerAddOn:EncodeToMask(frame.Conditions.chargesConditionalEnum, true)
    local encoded_shapeShiftEnum = ConditionerAddOn:EncodeToMask(frame.Conditions.shapeShiftEnum, true)
    local encoded_stacksAmount = ConditionerAddOn:EncodeToMask(frame.Conditions.stacksAmount)
    local encoded_secondsRemainingAmount = ConditionerAddOn:EncodeToMask(frame.Conditions.secondsRemainingAmount)
    local encoded_resourceAmount = ConditionerAddOn:EncodeToMask(frame.Conditions.resourceAmount)
    local encoded_alternateResourceAmount = ConditionerAddOn:EncodeToMask(frame.Conditions.alternateResourceAmount)
    local encoded_chargesAmount = ConditionerAddOn:EncodeToMask(frame.Conditions.chargesAmount)
    local stripped_activeAuraString = frame.Conditions.activeAuraString:gsub("_", "")
    local encoded_activeAuraString = string.format("_%s", stripped_activeAuraString) or "_"
    local stripped_myActiveAura = frame.Conditions.myActiveAura:gsub("_", "")
    local encoded_myActiveAura = string.format("_%s", stripped_myActiveAura) or "_"
    local stripped_keyBindingString = frame.Conditions.keyBindingString:gsub("_", "")
    local encoded_keyBindingString = withoutKeybinds and "_" or string.format("_%s", stripped_keyBindingString) or "_"
    local encoded_cooldownRemainingAmount = ConditionerAddOn:EncodeToMask(frame.Conditions.cooldownRemainingAmount)
    local encoded_cooldownRemainingConditionalEnum = ConditionerAddOn:EncodeToMask(frame.Conditions
        .cooldownRemainingEnum, true)

    local finalEncodedString = string.format(ConditionerAddOn.ConditionPatternMatch, boolString, boolStringShort,
        encoded_resourceTypeEnum, encoded_resourceConditionalEnum, encoded_alternateResourceTypeEnum,
        encoded_alternateResourceConditionalEnum, encoded_auraTargetEnum, encoded_stackConditionalEnum,
        encoded_chargesConditionalEnum, encoded_shapeShiftEnum, encoded_stacksAmount, encoded_secondsRemainingAmount,
        encoded_resourceAmount, encoded_alternateResourceAmount, encoded_chargesAmount, encoded_cooldownRemainingAmount,
        encoded_cooldownRemainingConditionalEnum, encoded_activeAuraString, encoded_keyBindingString,
        string.format("_%s", frame.Data.spellID), string.format("_%s", frame.Data.itemID),
        string.format("_%s", frame.Conditions.cooldownRemainingID), encoded_myActiveAura)

    local subEncodedString = ConditionerAddOn:SubEncode(finalEncodedString, false)
    -- print(string.format("ENCODED %s\n%s",finalEncodedString, subEncodedString))
    local testDecode = ConditionerAddOn:SubEncode(subEncodedString, true)
    if (testDecode == finalEncodedString) then
        -- print("SUCCESS")
        return subEncodedString
    else
        -- print("FAILED TO DECODE", #testDecode, #finalEncodedString)
        return
    end
end

function ConditionerAddOn:SetConditions(destFrame, conditionString, newSpellID, newItemID)
    if (not destFrame.Conditions) then
        return false
    end
    if (conditionString) then
        local subDecodedString = ConditionerAddOn:SubEncode(conditionString, true)
        if (not subDecodedString) then
            UIErrorsFrame:Clear()
            UIErrorsFrame:AddMessage("Please make sure you copied a valid loadout.", 0, 0.75, 1, 1)
            ConditionerAddOn:SetConditions(destFrame)
            return
        end
        -- print(string.format("DECODED %s\n%s", conditionString, subDecodedString)) -- ConditionerAddOn.ConditionPattern
        -- ADD NEW CONDITION FOR MY ACTIVE AURA
        local b, bShort, c, d, e, f, g, h, i, j, k, l, m, n, o, watched_Amount, cdR, p, q, spell_id, item_id,
        watched_ID, myActiveAura = subDecodedString:match(ConditionerAddOn.ConditionPattern)
        -- check if work is needed
        if (not C_Spell.DoesSpellExist(tonumber(spell_id))) then
            ConditionerAddOn:SetConditions(destFrame)
            return
        end
        local decoded_boolStrings = ConditionerAddOn:ConvertFromMask(b, true)
        local decoded_boolStringShort = ConditionerAddOn:ConvertFromMask(bShort, true)
        destFrame.Conditions.secondsRemainingBool = decoded_boolStrings[1]
        destFrame.Conditions.isInterruptBool = decoded_boolStrings[2]
        destFrame.Conditions.resourceUsePercentageBool = decoded_boolStrings[3]
        destFrame.Conditions.alternateResourceUsePercentageBool = decoded_boolStrings[4]
        destFrame.Conditions.onlyWhenReadyBool = decoded_boolStrings[5]
        destFrame.Conditions.highlightOnlyBool = decoded_boolStrings[6]
        destFrame.Conditions.buffBool = decoded_boolStrings[7]
        destFrame.Conditions.debuffBool = decoded_boolStrings[8]
        destFrame.Conditions.magicBool = decoded_boolStrings[9]
        destFrame.Conditions.curseBool = decoded_boolStrings[10]
        destFrame.Conditions.poisonBool = decoded_boolStrings[11]
        destFrame.Conditions.diseaseBool = decoded_boolStrings[12]
        destFrame.Conditions.resourceTypeEnum = ConditionerAddOn:ConvertFromMask(c)
        destFrame.Conditions.resourceConditionalEnum = ConditionerAddOn:ConvertFromMask(d)
        destFrame.Conditions.alternateResourceTypeEnum = ConditionerAddOn:ConvertFromMask(e)
        destFrame.Conditions.alternateResourceConditionalEnum = ConditionerAddOn:ConvertFromMask(f)
        destFrame.Conditions.auraTargetEnum = ConditionerAddOn:ConvertFromMask(g)
        destFrame.Conditions.stackConditionalEnum = ConditionerAddOn:ConvertFromMask(h)
        destFrame.Conditions.chargesConditionalEnum = ConditionerAddOn:ConvertFromMask(i)
        destFrame.Conditions.shapeShiftEnum = ConditionerAddOn:ConvertFromMask(j)
        destFrame.Conditions.stacksAmount = ConditionerAddOn:ConvertFromMask(k)
        destFrame.Conditions.secondsRemainingAmount = ConditionerAddOn:ConvertFromMask(l)
        destFrame.Conditions.resourceAmount = ConditionerAddOn:ConvertFromMask(m)
        destFrame.Conditions.alternateResourceAmount = ConditionerAddOn:ConvertFromMask(n)
        destFrame.Conditions.chargesAmount = ConditionerAddOn:ConvertFromMask(o)
        destFrame.Conditions.activeAuraString = p
        destFrame.Conditions.keyBindingString = q
        destFrame.Data.spellID = tonumber(spell_id)
        destFrame.Data.itemID = tonumber(item_id)
        destFrame.Conditions.cooldownRemainingID = tonumber(watched_ID)
        destFrame.Conditions.cooldownRemainingAmount = ConditionerAddOn:ConvertFromMask(watched_Amount)
        destFrame.Conditions.cooldownRemainingIsItemID = decoded_boolStringShort[1]
        destFrame.Conditions.onlyInRange = decoded_boolStringShort[2]
        destFrame.Conditions.onlyDuringCC = decoded_boolStringShort[3]
        destFrame.Conditions.showInAoeRotation = decoded_boolStringShort[4]
        destFrame.Conditions.hideWhileCasting = decoded_boolStringShort[5]
        destFrame.Conditions.canCast = decoded_boolStringShort[6]
        destFrame.Conditions.cooldownRemainingEnum = ConditionerAddOn:ConvertFromMask(cdR)
        destFrame.Conditions.myActiveAura = myActiveAura
    else
        -- init
        destFrame.Data.spellID = newSpellID or 0
        destFrame.Data.itemID = newItemID or 0
        destFrame.Conditions = {
            -- strings
            activeAuraString = "",
            keyBindingString = "",
            myActiveAura = "",
            -- bools
            secondsRemainingBool = false,
            isInterruptBool = false,
            resourceUsePercentageBool = false,
            alternateResourceUsePercentageBool = false,
            onlyWhenReadyBool = false,
            highlightOnlyBool = false,
            buffBool = false,
            debuffBool = false,
            magicBool = false,
            curseBool = false,
            poisonBool = false,
            diseaseBool = false,
            -- boolShort
            cooldownRemainingIsItemID = false,
            onlyInRange = false,
            onlyDuringCC = false,
            canCast = false,
            hideWhileCasting = false,
            showInAoeRotation = false,
            -- enums
            resourceTypeEnum = 0,
            resourceConditionalEnum = 0,
            alternateResourceTypeEnum = 0,
            alternateResourceConditionalEnum = 0,
            auraTargetEnum = 0,
            stackConditionalEnum = 0,
            chargesConditionalEnum = 0,
            shapeShiftEnum = 0,
            cooldownRemainingEnum = 0,
            -- amounts
            stacksAmount = 0,
            secondsRemainingAmount = 0,
            resourceAmount = 0,
            alternateResourceAmount = 0,
            chargesAmount = 0,
            cooldownRemainingID = 0,
            cooldownRemainingAmount = 0
        }
    end
    destFrame:UpdateTexture()
end

function ConditionerAddOn:GetCursorInfo()
    local cursorType, newItemID, isPetSpell, newSpellID = GetCursorInfo()
    if (cursorType == "spell") then
        newItemID = 0
    elseif (cursorType == "petaction") and (isPetSpell) then
        newSpellID = newItemID
        newItemID = 0
    elseif (cursorType == "item") then
        _, newSpellID = GetItemSpell(newItemID)
        if (not newSpellID) then
            ClearCursor()
            return false, false, true
        end
    else
        ClearCursor()
        return false, false
    end

    return newSpellID, newItemID
end

function ConditionerAddOn:PriorityClickHandler(frame, button)
    if (ConditionerAddOn.SharedConditionerFrame) and (ConditionerAddOn.SharedConditionerFrame.EditBoxes) then
        for k, v in pairs(ConditionerAddOn.SharedConditionerFrame.EditBoxes) do
            v:ClearFocus()
        end
    end
    local newSpellID, newItemID, isBadItem = ConditionerAddOn:GetCursorInfo()
    local frameSpellID, frameItemID = -1, -1
    if (frame.Data) then
        frameSpellID = frame.Data.spellID
        frameItemID = frame.Data.itemID
    end
    if (button == "LeftButton") then
        if (newSpellID) then
            ConditionerAddOn:Place(frame)
        else
            if (not UnitAffectingCombat("player")) then
                if (frameSpellID > 0) and (not isBadItem) then
                    ConditionerAddOn:Delete(frame, true)
                end
            end
        end
    elseif (button == "RightButton") then
        if (not newSpellID) and (frameSpellID > 0) then
            ConditionerAddOn:Delete(frame)
        end
    end
    if (ConditionerAddOn.SharedConditionerFrame) then
        ConditionerAddOn.SharedConditionerFrame:Hide()
    end
end

function ConditionerAddOn:InitSavedVars()
    ConditionerAddOn_SavedVariables.Options.TaperSize = ConditionerAddOn_SavedVariables.Options.TaperSize or 80
    ConditionerAddOn_SavedVariables.Options.NumTrackedFrames =
        ConditionerAddOn_SavedVariables.Options.NumTrackedFrames or 5
    ConditionerAddOn_SavedVariables.Options.Opacity = ConditionerAddOn_SavedVariables.Options.Opacity or 100
    ConditionerAddOn_SavedVariables.Options.ClipGCD = ConditionerAddOn_SavedVariables.Options.ClipGCD or 0
    ConditionerAddOn_SavedVariables.Options.MouseOverOffsetX = ConditionerAddOn_SavedVariables.Options.MouseOverOffsetX
        or 0
    ConditionerAddOn_SavedVariables.Options.MouseOverOffsetY = ConditionerAddOn_SavedVariables.Options.MouseOverOffsetY
        or 0
    ConditionerAddOn_SavedVariables.Options.MouseOverIconScale = ConditionerAddOn_SavedVariables.Options
        .MouseOverIconScale
        or 50
    ConditionerAddOn_SavedVariables.Options.AoeNumTrackedFrames =
        ConditionerAddOn_SavedVariables.Options.AoeNumTrackedFrames or 5
    ConditionerAddOn_SavedVariables.Options.MouseoverNumTrackedFrames =
        ConditionerAddOn_SavedVariables.Options.MouseoverNumTrackedFrames or 5
end

function ConditionerAddOn:NewSlider(parent, name, minText, maxText, min_Value, max_Value, sliderText, initValue, key,
                                    hidePercent)
    local o = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    o.textLow = _G[name .. "Low"]
    o.textHigh = _G[name .. "High"]
    o.text = _G[name .. "Text"]
    o.textLow:SetText(minText)
    o.textHigh:SetText(maxText)
    o.text:SetTextColor(0.1, 0.9, 1, 1)
    o:SetMinMaxValues(min_Value, max_Value)
    o.minValue, o.maxValue = o:GetMinMaxValues()
    o:SetValue(initValue)
    o:SetValueStep(1)

    o:SetScript("OnValueChanged", function(self, event, ...)
        o:SetValue(o:GetValue())
        ConditionerAddOn:InitSavedVars()
        ConditionerAddOn_SavedVariables.Options[key] = o:GetValue()
        self.text:SetText(
            string.format("%s (%s%s)", sliderText, o:GetValue(),
                hidePercent and "" or "%"))
        if (key == "TaperSize" or key == "Opacity") then
            ConditionerAddOn:ResizeTrackers()
        end
    end)

    o:SetScript("OnShow", function(self, ...)
        ConditionerAddOn:InitSavedVars()
        o:SetValue(ConditionerAddOn_SavedVariables.Options[key])
        self.text:SetText(
            string.format("%s (%s%s)", sliderText, o:GetValue(),
                hidePercent and "" or "%"))
    end)

    return o
end

function ConditionerAddOn:NewInputBox(parent, key, numbersOnly)
    local o = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    o:SetSize(50, 25)
    o:SetAutoFocus(false)
    o:SetNumeric(numbersOnly)
    o:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    o:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    o:SetScript("OnMouseDown", function(self, button)
        if (button == "RightButton") then
            if (numbersOnly) then
                self:SetNumber(0)
            else
                self:SetText("")
            end
        end
        if (ConditionerAddOn.SharedConditionerFrame.DispelFilterButton) and
            (ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor) then
            ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:Hide()
        end
        ConditionerCloseDropDownMenus()
    end)
    o:SetScript("OnChar", function(self, text)
        if (numbersOnly) then
            local maxNum = 100000000
            if (o.linkedPercentBox) then
                self:SetNumber(math.min(self:GetNumber(), (o.linkedPercentBox:GetChecked()) and 100 or maxNum))
            else
                self:SetNumber(math.min(self:GetNumber(), maxNum))
            end
        end
    end)
    o:SetScript("OnEditFocusLost", function(self)
        local strippedString = self:GetText():gsub("_", " ")
        ConditionerAddOn:SetCurrentCondition(key, (numbersOnly) and self:GetNumber() or strippedString)
        if (ConditionerAddOn.SharedConditionerFrame.ResultsBox) and
            (ConditionerAddOn.SharedConditionerFrame.ResultsBox:IsShown()) then
            ConditionerAddOn.SharedConditionerFrame.ResultsBox:ClearResults()
            ConditionerAddOn.SharedConditionerFrame.ResultsBox:FixBackground()
        end
    end)
    o:SetScript("OnEnter", function(self, ...)
        if (o.tooltip) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
            GameTooltip:SetText(o.title or "Conditioner", 0, 0.75, 1)
            GameTooltip:AddLine(o.tooltip, 1, 1, 1, true)
            GameTooltip:SetMinimumWidth(150)
            GameTooltip:Show()
        end
    end)
    o:SetScript("OnLeave", function(self, ...)
        GameTooltip:Hide()
    end)

    function o:Update()
        if (self:IsNumeric()) then
            self:SetNumber(ConditionerAddOn.CurrentPriorityButton.Conditions[key])
        else
            self:SetText(ConditionerAddOn.CurrentPriorityButton.Conditions[key])
        end
    end

    return o
end

function ConditionerAddOn:NewTrackingFrame()
    local o = CreateFrame("Frame", nil, UIParent)
    o.parentNode = false
    o.isActive = false
    o.Icon = o:CreateTexture()
    o.Icon:SetPoint("BOTTOMLEFT", o, "BOTTOMLEFT")
    o.Icon:SetPoint("TOPRIGHT", o, "TOPRIGHT")
    o.Icon:SetDrawLayer("BACKGROUND")
    o.cooldown = CreateFrame("Cooldown", nil, o, "CooldownFrameTemplate")
    o.cooldown:SetAllPoints(o)
    o.cooldown:SetHideCountdownNumbers(true)
    o.KeybindFrame = CreateFrame("Frame", nil, o)
    o.KeybindFrame:SetAllPoints(o)
    o.KeybindFrame:SetFrameStrata(o:GetFrameStrata())
    o.Keybind = o.KeybindFrame:CreateFontString(nil, "OVERLAY", "SystemFont_OutlineThick_Huge2")
    o.Keybind:SetPoint("BOTTOMLEFT", o, "BOTTOMLEFT", 8, 6.25)
    o.Keybind:SetJustifyH("LEFT")
    o.Keybind:SetJustifyV("BOTTOM")
    o.Keybind:SetTextColor(0, 1, 1, 1)
    o.Countdown = CreateFrame("Frame", nil, o)
    o.Countdown:SetPoint("BOTTOMLEFT", o, "CENTER")
    o.Countdown:SetPoint("BOTTOMRIGHT", o, "RIGHT")
    o.Countdown:SetHeight(10)
    o.Countdown.Texture = o.Countdown:CreateTexture()
    o.Countdown.Texture:SetDrawLayer("OVERLAY")
    o.Countdown.Texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    o.Countdown.Text = o.Countdown:CreateFontString(nil, "OVERLAY", "SystemFont_Huge1_Outline")
    o.Countdown.Text:SetPoint("TOPLEFT", o, "TOPLEFT")
    o.Countdown.Icon = o.Countdown:CreateTexture()
    o.Countdown.Icon:SetPoint("TOPRIGHT", o, "TOPRIGHT")
    o.Countdown.Icon:SetPoint("BOTTOMLEFT", o, "CENTER")
    o.Countdown.Icon:SetAlpha(0.9)
    o.Countdown.Texture:SetPoint("BOTTOMLEFT", o, "CENTER")
    o.Countdown.Texture:SetPoint("BOTTOMRIGHT", o.Countdown.Icon, "RIGHT")
    o.Countdown.Texture:SetPoint("TOP", o.Countdown, "TOP")
    o.Countdown.Texture:SetAlpha(0.5)
    return o
end

function ConditionerAddOn:UpdateTrackerPoints()
    ConditionerAddOn.TrackingFrames = ConditionerAddOn.TrackingFrames or {}
    ConditionerAddOn_SavedVariables.Options.AnchorDirection =
        ConditionerAddOn_SavedVariables.Options.AnchorDirection or 0
    for k, v in ipairs(ConditionerAddOn.TrackingFrames) do
        if (v.parentNode ~= ConditionerAddOn.TrackedFrameDragAnchor) then
            v:ClearAllPoints()
            if (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 0) then
                v:SetPoint("BOTTOMRIGHT", v.parentNode, "BOTTOMLEFT", -2, 0)
            elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 1) then
                v:SetPoint("BOTTOM", v.parentNode, "TOP", 0, 2)
            elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 2) then
                v:SetPoint("BOTTOMLEFT", v.parentNode, "BOTTOMRIGHT", 2, 0)
            elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 3) then
                v:SetPoint("TOP", v.parentNode, "BOTTOM", 0, -2)
            end
        end
        -- keybind adjustment for main frame
        if (k == 1) then
            v.Keybind:ClearAllPoints()
            if (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 2) then
                v.Keybind:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -v:GetWidth() * 0.08, v:GetHeight() * 0.0325)
            else
                v.Keybind:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", v:GetWidth() * 0.08, v:GetHeight() * 0.0325)
            end
        end
    end
end

function ConditionerAddOn:ClearTrackers()
    ConditionerAddOn.TrackingFrames = ConditionerAddOn.TrackingFrames or {}
    for k, v in ipairs(ConditionerAddOn.TrackingFrames) do
        v.isActive = false
        v:Hide()
    end
end

function ConditionerAddOn:ResizeTrackers()
    ConditionerAddOn.TrackingFrames = ConditionerAddOn.TrackingFrames or {}
    ConditionerAddOn_SavedVariables.Options.TrackedFrameSize =
        ConditionerAddOn_SavedVariables.Options.TrackedFrameSize or 100
    ConditionerAddOn_SavedVariables.Options.TaperSize = ConditionerAddOn_SavedVariables.Options.TaperSize or 80
    ConditionerAddOn_SavedVariables.Options.Opacity = ConditionerAddOn_SavedVariables.Options.Opacity or 100
    local modAmount = ConditionerAddOn_SavedVariables.Options.TrackedFrameSize
    for k, v in ipairs(ConditionerAddOn.TrackingFrames) do
        local mult = math.pow(ConditionerAddOn_SavedVariables.Options.TaperSize / 100, k - 1)
        local myNewSize = ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * mult
        v:SetSize(myNewSize, myNewSize)
        -- keybind adjustment for main frame
        if (k == 1) then
            v.Keybind:ClearAllPoints()
            if (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 2) then
                v.Keybind:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -myNewSize * 0.08, myNewSize * 0.0325)
            else
                v.Keybind:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", myNewSize * 0.08, myNewSize * 0.0325)
            end
        else
            v.Keybind:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", myNewSize * 0.08, myNewSize * 0.0325)
        end
        v.Icon:SetAlpha(ConditionerAddOn_SavedVariables.Options.Opacity / 100)
        ConditionerAddOn:AddBorder(v)
        v.Keybind:SetFont("Fonts\\FRIZQT__.TTF", math.ceil(0.26 * myNewSize), "OUTLINE, THICK")
        v.Countdown.Text:SetFont("Fonts\\FRIZQT__.TTF", math.ceil(0.24 * myNewSize), "OUTLINE, THICK")
    end
end

function ConditionerAddOn:CompareValues(leftValue, operatorEnum, rightValue)
    leftValue = leftValue or 0
    if (operatorEnum == 1) then
        return (leftValue > rightValue)
    elseif (operatorEnum == 2) then
        return (leftValue >= rightValue)
    elseif (operatorEnum == 3) then
        return (leftValue == rightValue)
    elseif (operatorEnum == 4) then
        return (leftValue <= rightValue)
    elseif (operatorEnum == 5) then
        return (leftValue < rightValue)
    elseif (operatorEnum == 6) then
        return (leftValue ~= rightValue)
    end
    return true
end

function ConditionerAddOn:CollectMouseOverSpells(sortedList)
    ConditionerAddOn:InitSavedVars()
    ConditionerAddOn:HideTrackerPool(ConditionerAddOn.MouseIconTracker.Pool)
    local lastParentFrame = ConditionerAddOn.MouseIconTracker
    local found = 0
    local scale = UIParent:GetScale() * 0.25
    for i, v in ipairs(sortedList) do
        if (v.isMouseover and found < ConditionerAddOn_SavedVariables.Options.MouseoverNumTrackedFrames) then
            local keybind = ConditionerAddOn.PriorityButtons[v.priority].Conditions.keyBindingString
            local frame = ConditionerAddOn:GetTrackerFromPool(ConditionerAddOn.MouseIconTracker.Pool)
            frame.available = false
            frame.Texture:SetTexture(v.texture)
            frame:ClearAllPoints()
            local isCoolingDown, cooldownDuration = frame.Cooldown:GetCooldownTimes()
            if (cooldownDuration ~= v.duration) then
                frame.Cooldown:SetCooldown(v.startTime, v.duration)
            end
            -- attach it to lastParentFrame
            -- match lastParentFrame if it is the MouseIconTracker
            if (lastParentFrame == ConditionerAddOn.MouseIconTracker) then
                frame:SetAllPoints(lastParentFrame)
            else
                if (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 0) then
                    frame:SetPoint("BOTTOMRIGHT", lastParentFrame, "BOTTOMLEFT", -2, 0)
                elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 1) then
                    frame:SetPoint("BOTTOM", lastParentFrame, "TOP", 0, 2)
                elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 2) then
                    frame:SetPoint("BOTTOMLEFT", lastParentFrame, "BOTTOMRIGHT", 2, 0)
                elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 3) then
                    frame:SetPoint("TOP", lastParentFrame, "BOTTOM", 0, -2)
                end
            end

            frame:SetSize(lastParentFrame:GetSize())
            frame:SetAlpha(ConditionerAddOn_SavedVariables.Options.Opacity / 100)
            frame.Keybind:SetFont("Fonts\\FRIZQT__.TTF",
                ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * scale, "OUTLINE, THICK")
            frame.Keybind:SetText(keybind)
            frame.Keybind:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT",
                ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * 0.0325 * 0.5,
                ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * 0.0325 * 0.5)
            if (not v.range) or (v.range == 1) then
                frame.Texture:SetDesaturated(false)
                frame.Keybind:SetTextColor(0, 1, 1, 1)
            else
                frame.Texture:SetDesaturated(true)
                frame.Keybind:SetTextColor(1, 0.3, 0.75, 1)
            end

            frame:Show()
            lastParentFrame = frame
            found = found + 1
        end
    end
end

function ConditionerAddOn:CollectAoeSpells(sortedList)
    ConditionerAddOn:InitSavedVars()
    ConditionerAddOn:HideTrackerPool(ConditionerAddOn.AoeRotation.Pool)
    local lastParentFrame = ConditionerAddOn.AoeRotation.Anchor
    local found = 0
    local scale = UIParent:GetScale() * 0.25
    for i, v in ipairs(sortedList) do
        if (v.isAoe and found < ConditionerAddOn_SavedVariables.Options.AoeNumTrackedFrames) then
            local keybind = ConditionerAddOn.PriorityButtons[v.priority].Conditions.keyBindingString
            local frame = ConditionerAddOn:GetTrackerFromPool(ConditionerAddOn.AoeRotation.Pool)
            frame.available = false
            frame.Texture:SetTexture(v.texture)
            frame:ClearAllPoints()
            local isCoolingDown, cooldownDuration = frame.Cooldown:GetCooldownTimes()
            if (cooldownDuration ~= v.duration) then
                frame.Cooldown:SetCooldown(v.startTime, v.duration)
            end
            -- attach it to lastParentFrame
            -- match lastParentFrame if it is the AoeRotation
            if (lastParentFrame == ConditionerAddOn.AoeRotation.Anchor) then
                frame:SetAllPoints(lastParentFrame)
            else
                if (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 0) then
                    frame:SetPoint("BOTTOMRIGHT", lastParentFrame, "BOTTOMLEFT", -2, 0)
                elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 1) then
                    frame:SetPoint("BOTTOM", lastParentFrame, "TOP", 0, 2)
                elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 2) then
                    frame:SetPoint("BOTTOMLEFT", lastParentFrame, "BOTTOMRIGHT", 2, 0)
                elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 3) then
                    frame:SetPoint("TOP", lastParentFrame, "BOTTOM", 0, -2)
                end
            end

            frame:SetSize(lastParentFrame:GetSize())
            frame:SetAlpha(ConditionerAddOn_SavedVariables.Options.Opacity / 100)
            frame.Keybind:SetFont("Fonts\\FRIZQT__.TTF",
                ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * scale, "OUTLINE, THICK")
            frame.Keybind:SetText(keybind)
            frame.Keybind:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT",
                ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * 0.0325 * 0.5,
                ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * 0.0325 * 0.5)
            if (not v.range) or (v.range == 1) then
                frame.Texture:SetDesaturated(false)
                frame.Keybind:SetTextColor(0, 1, 1, 1)
            else
                frame.Texture:SetDesaturated(true)
                frame.Keybind:SetTextColor(1, 0.3, 0.75, 1)
            end

            frame:Show()
            lastParentFrame = frame
            found = found + 1
        end
    end
end

function ConditionerAddOn:GetCooldownList()
    local validSpells = {}
    local found = {}
    for k, v in ipairs(ConditionerAddOn.PriorityButtons) do
        local spellTimeRemaining, spellGCD, s, d, inRange, auraTexture, auraDuration, auraTimestamp, isMouseover, isAoe =
            ConditionerAddOn:CheckCondition(v)
        local id = v.Data.spellID
        if (spellTimeRemaining) and (not found[id]) then
            found[id] = true
            table.insert(validSpells, {
                priority = k,
                time = spellTimeRemaining,
                gcd = spellGCD,
                startTime = s,
                duration = d,
                texture = v.CurrentTexture,
                range = inRange,
                auraIcon = auraTexture,
                auraTime = auraDuration,
                auraTS = auraTimestamp,
                isMouseover = isMouseover,
                isAoe = isAoe
            })
        end
    end

    ConditionerAddOn:MergeSort(validSpells)

    return validSpells
end

function ConditionerAddOn:MergeSort(list)
    if (#list > 1) then
        local middle = math.ceil(#list / 2)
        local leftHalf, rightHalf = {}, {}
        for i = 1, middle do
            table.insert(leftHalf, list[i])
        end
        for i = middle + 1, #list do
            table.insert(rightHalf, list[i])
        end
        ConditionerAddOn:MergeSort(leftHalf)
        ConditionerAddOn:MergeSort(rightHalf)
        ConditionerAddOn:Merge(list, leftHalf, rightHalf)
    end
end

function ConditionerAddOn:Merge(list, left, right)
    local gcdClipAmount = (ConditionerAddOn_SavedVariables.Options.ClipGCD or 0) / 100
    local hasteMult = 1 / (1 + (GetHaste() / 100))
    local i, j, k = 1, 1, 1
    while ((i <= #left) and (j <= #right)) do
        local a, b = left[i], right[j]
        if (a.priority < b.priority) then
            if (a.time <= b.time + hasteMult * b.gcd * gcdClipAmount) then
                list[k] = a
                i = i + 1
            else
                list[k] = b
                j = j + 1
            end
        else
            if (b.time <= a.time + hasteMult * a.gcd * gcdClipAmount) then
                list[k] = b
                j = j + 1
            else
                list[k] = a
                i = i + 1
            end
        end
        k = k + 1
    end
    while (i <= #left) do
        list[k] = left[i]
        i = i + 1
        k = k + 1
    end
    while (j <= #right) do
        list[k] = right[j]
        j = j + 1
        k = k + 1
    end
end

function ConditionerAddOn:CheckCondition(priorityButton)
    local spellID, itemID, Conditions = priorityButton.Data.spellID, priorityButton.Data.itemID,
        priorityButton.Conditions

    -- the button has no data
    if (spellID + itemID == 0) then
        -- print("FAILED - NO DATA")
        return false
    end
    -- bug fix override spells
    spellID = ConditionerGetOverrideSpell(spellID)

    -- the player doesn't know the spell or it isn't in their spellbooks or they don't have any more of that item
    -- more override nonsense
    local hasSlot = FindSpellBookSlotBySpellID(spellID)
    if (hasSlot) then
        -- local bookNameCheck = GetSpellBookItemName(hasSlot, "spell")
        hasSlot = (not IsPassiveSpell(hasSlot, "spell"))
    end
    hasSlot = (itemID > 0) and GetItemCount(itemID) or hasSlot
    if (not hasSlot) then
        hasSlot = FindSpellBookSlotBySpellID(spellID, "pet")
    end
    if (not hasSlot) or (hasSlot == 0) then
        -- print("FAILED - KNOWN")
        return false
    end

    -- Conditions.showInAoeRotation repurposed to AoE ability
    local isAoe = Conditions.showInAoeRotation

    -- onlyDuringCC
    if (Conditions.onlyDuringCC) and (HasFullControl()) then
        -- print("FAILED - CROWD CONTROL")
        return false
    end
    -- only when highlighted, can't work with items, so they have to turn it off
    if (Conditions.highlightOnlyBool) and (not ConditionerIsSpellOverlayed(spellID)) then
        -- print("FAILED - HIGHLIGHTED")
        return false
    end
    -- canCast
    if (Conditions.canCast) and (not IsUsableSpell(spellID)) then
        -- print("FAILED - CAN CAST")
        return false
    end

    -- onlyWhenReadyBool
    if (Conditions.onlyWhenReadyBool) then
        local testFunc = (itemID > 0) and GetItemCooldown or GetSpellCooldown
        local testID = (itemID > 0) and itemID or spellID
        local _, itemSpell = GetItemSpell(itemID)
        local _, GCDTime = GetSpellBaseCooldown(spellID)
        if (itemID > 0) then
            _, GCDTime = GetSpellBaseCooldown(itemSpell)
        end
        local _, isReady = testFunc(testID)
        if (isReady > GCDTime / 1000) then
            -- print("FAILED - READY")
            return false
        end
    end

    -- target Unit exists
    local targetUnitEnum, targetUnitToken = Conditions.auraTargetEnum, "player"
    if (targetUnitEnum == 1) then
        targetUnitToken = "player"
    elseif (
            targetUnitEnum == 2 or targetUnitEnum == 3 or targetUnitEnum == 4 or targetUnitEnum == 13 or targetUnitEnum ==
            14 or targetUnitEnum == 15) then
        targetUnitToken = "target"
    elseif (targetUnitEnum == 5 or targetUnitEnum == 6 or targetUnitEnum == 7) then
        targetUnitToken = "mouseover"
    elseif (targetUnitEnum == 8) then
        targetUnitToken = "pet"
    elseif (targetUnitEnum == 9) then
        targetUnitToken = "pettarget"
    elseif (targetUnitEnum == 10) then
        targetUnitToken = "focus"
    elseif (targetUnitEnum == 11) then
        targetUnitToken = "focustarget"
    elseif (targetUnitEnum == 12) then
        targetUnitToken = "targettarget"
    elseif (targetUnitEnum == 16) then
        targetUnitToken = "anyenemy"
    elseif (targetUnitEnum == 17) then
        targetUnitToken = "anyfriend"
    elseif (targetUnitEnum == 18) then
        targetUnitToken = "anyinteract"
    elseif (targetUnitEnum == 19) then
        targetUnitToken = "softenemy"
    elseif (targetUnitEnum == 20) then
        targetUnitToken = "softfriend"
    elseif (targetUnitEnum == 21) then
        targetUnitToken = "softinteract"
    end

    -- is mouseover spell
    local isMouseover = (targetUnitToken == "mouseover")
    if (UnitIsDead(targetUnitToken)) then
        return false
    end

    -- I Am Tanking Elite+ 22
    if (targetUnitEnum == 22) then
        local isTanking = UnitDetailedThreatSituation("player", "target")
        local isElite = ConditionerAddOn:IsEliteOrHigher("target")

        if (not isElite) or (UnitExists("target") and not isTanking) then
            return false
        end
    end

    -- I Am Not Tanking Elite+ 23
    if (targetUnitEnum == 23) then
        local isTanking = UnitDetailedThreatSituation("player", "target")
        local isElite = ConditionerAddOn:IsEliteOrHigher("target")
        if (not isElite) or (UnitExists("target") and isTanking) then
            return false
        end
    end

    -- I Am Tanking anything 24
    if (targetUnitEnum == 24) then
        local targetingMe = UnitGUID("player") == UnitGUID("targettarget")
        if (not targetingMe or not UnitExists("target")) then
            return false
        end
    end

    -- I Am Not Tanking anything 25
    if (targetUnitEnum == 25) then
        local targetingMe = UnitGUID("player") == UnitGUID("targettarget")
        if (targetingMe or not UnitExists("target")) then
            return false
        end
    end

    -- if we don't have a target other than myself then fail
    if (not UnitExists(targetUnitToken)) then
        return false
    end

    -- 2/5 enemy
    if (targetUnitEnum == 2 or targetUnitEnum == 5 or targetUnitEnum == 14) and
        (not UnitCanAttack("player", targetUnitToken)) then
        -- print("FAILED - ENEMY TARGET")
        return false
    end
    -- 3/6 friend
    if (targetUnitEnum == 3 or targetUnitEnum == 6 or targetUnitEnum == 13) and
        (UnitCanAttack("player", targetUnitToken)) then
        -- print("FAILED - FRIENDLY TARGET")
        return false
    end

    -- isPlayer
    if (targetUnitEnum == 13 or targetUnitEnum == 14 or targetUnitEnum == 15) and (not UnitIsPlayer(targetUnitToken)) then
        return false
    end

    -- shapeShiftEnum
    if (Conditions.shapeShiftEnum > 0) then
        local shapeShiftChoice = ConditionerAddOn.Enums.shapeShiftChoicesEnum[Conditions.shapeShiftEnum]
        local noForm = shapeShiftChoice == "No Form"
        local currentForm = GetShapeshiftForm and GetShapeshiftForm() or -1
        local stanceId = Conditions.shapeShiftEnum - 10
        local isActive = true
        if (stanceId > 0) then
            local _, active, _, _ = GetShapeshiftFormInfo(stanceId)
            isActive = active
        end
        if (noForm and currentForm ~= 0) then
            return false
        end
        if (not noForm and not ConditionerAddOn.BuffExists("player", shapeShiftChoice) and not isActive) then
            -- print("FAILED - SHAPESHIFT")
            return false
        end
    end

    -- hideWhileCasting
    -- repurposed inStealth for casters
    if (Conditions.hideWhileCasting) then
        local _, _, _, _, _, _, _, _, myCastSpellID = ConditionerUnitCastingInfo("player")
        local _, _, _, _, _, _, _, myChannelSpellID = ConditionerUnitChannelInfo("player")
        -- am I casting the spell already?
        if (spellID == myCastSpellID) or (spellID == myChannelSpellID) or IsCurrentSpell(spellID) then
            return false
        end
    end

    local inRange = false
    if (itemID > 0) then
        inRange = IsItemInRange(itemID, targetUnitToken)
        inRange = (inRange == nil) and 1 or inRange
    else
        local spellBookSlot = FindSpellBookSlotBySpellID(spellID)
        local petBookSlot = FindSpellBookSlotBySpellID(spellID, "pet")
        if (petBookSlot) then
            inRange = IsSpellInRange(petBookSlot, "pet", targetUnitToken)
        else
            inRange = IsSpellInRange(spellBookSlot, "spell", targetUnitToken)
        end
    end

    -- onlyInRange
    if (Conditions.onlyInRange) then
        if (inRange) and (inRange == 0) then
            -- print("FAILED - RANGE")
            return false
        end
    end

    -- charges
    if (Conditions.chargesConditionalEnum > 0) then
        local rightValue = Conditions.chargesAmount
        local leftValue = (itemID > 0) and (GetItemCount(itemID)) or (GetSpellCharges(spellID)) or
            (GetSpellCount(spellID))
        local satisfied = ConditionerAddOn:CompareValues(leftValue, Conditions.chargesConditionalEnum, rightValue)
        if (not satisfied) then
            -- print("FAILED - CHARGES")
            return false
        end
    end

    -- dispel masks
    if (Conditions.magicBool or Conditions.curseBool or Conditions.poisonBool or Conditions.diseaseBool) then
        local targetMaskSum = 0
        targetMaskSum = targetMaskSum + ((Conditions.magicBool) and 1 or 0)
        targetMaskSum = targetMaskSum + ((Conditions.curseBool) and 2 or 0)
        targetMaskSum = targetMaskSum + ((Conditions.poisonBool) and 4 or 0)
        targetMaskSum = targetMaskSum + ((Conditions.diseaseBool) and 8 or 0)
        local buffDispelTypes = {
            ["Curse"] = false,
            ["Disease"] = false,
            ["Magic"] = false,
            ["Poison"] = false
        }
        local debuffDispelTypes = {
            ["Curse"] = false,
            ["Disease"] = false,
            ["Magic"] = false,
            ["Poison"] = false
        }
        for i = 1, 64 do
            local _, _, _, dispelBuffType = UnitBuff(targetUnitToken, i)
            local _, _, _, dispelDebuffType = UnitDebuff(targetUnitToken, i)
            buffDispelTypes[dispelBuffType or 0] = (dispelBuffType) and true or false
            debuffDispelTypes[dispelDebuffType or 0] = (dispelDebuffType) and true or false
        end
        local finalBuffMask = 0
        finalBuffMask = finalBuffMask + ((buffDispelTypes["Magic"]) and 1 or 0)
        finalBuffMask = finalBuffMask + ((buffDispelTypes["Curse"]) and 2 or 0)
        finalBuffMask = finalBuffMask + ((buffDispelTypes["Poison"]) and 4 or 0)
        finalBuffMask = finalBuffMask + ((buffDispelTypes["Disease"]) and 8 or 0)
        local finalDebuffMask = 0
        finalDebuffMask = finalDebuffMask + ((debuffDispelTypes["Magic"]) and 1 or 0)
        finalDebuffMask = finalDebuffMask + ((debuffDispelTypes["Curse"]) and 2 or 0)
        finalDebuffMask = finalDebuffMask + ((debuffDispelTypes["Poison"]) and 4 or 0)
        finalDebuffMask = finalDebuffMask + ((debuffDispelTypes["Disease"]) and 8 or 0)
        local result = 0
        if (Conditions.buffBool and not Conditions.debuffBool) then
            result = bit.band(targetMaskSum, finalBuffMask)
        elseif (Conditions.debuffBool and not Conditions.buffBool) then
            result = bit.band(targetMaskSum, finalDebuffMask)
        else
            result = math.max(bit.band(targetMaskSum, finalBuffMask), bit.band(targetMaskSum, finalDebuffMask))
        end
        if (result == 0) then
            -- print("FAILED - DISPEL MASKS")
            return false
        end
    end

    -- is interrupt
    if (Conditions.isInterruptBool) then
        local castSpellName, _, castSpellTexture, castStart, castEnd, _, _, uninterruptable, castSpellID =
            ConditionerUnitCastingInfo(targetUnitToken == "player" and "target" or targetUnitToken)
        local channelSpellName, _, channelSpellTexture, channelStart, channelEnd, _, notInterruptible, channelSpellID =
            ConditionerUnitChannelInfo(targetUnitToken == "player" and "target" or targetUnitToken)
        if (castSpellName) or (channelSpellName) then
            if (uninterruptable or notInterruptible) then
                -- print("FAILED - UNINTERRUPTABLE")
                return false
            else
                local cdFunc = (itemID > 0) and GetItemCooldown or GetSpellCooldown
                local cdID = (itemID > 0) and itemID or spellID
                local myStartTime, myDuration = cdFunc(cdID)
                local myEndTime = (myDuration == 0) and 0 or (myStartTime + myDuration) * 1000
                local enemyEndTime = castEnd or channelEnd
                if (enemyEndTime < myEndTime) then
                    -- print("FAILED - NOT ENOUGH TIME")
                    return false
                end
            end
        else
            -- print("FAILED - NOT CASTING")
            return false
        end
    end

    local activeAuraName = Conditions.activeAuraString
    local myActiveAuraName = Conditions.myActiveAura
    local auraName, auraIcon, auraStacks, _, auraDuration, auraExpireTimestamp, _, auraIsStealable, _, auraSpellID, _,
    _, _, _, auraTimeMod = ConditionerAddOn.DebuffExists(targetUnitToken, activeAuraName, "PLAYER")
    if (not auraName) then
        auraName, auraIcon, auraStacks, _, auraDuration, auraExpireTimestamp, _, auraIsStealable, _, auraSpellID, _, _, _
        , _, auraTimeMod =
            ConditionerAddOn.BuffExists(targetUnitToken, activeAuraName, "PLAYER")
    end

    -- check for my active aura
    if (myActiveAuraName ~= "") then
        -- the player wants to know if they have an active aura
        local isMyAuraActive = ConditionerAddOn.DebuffExists("player", myActiveAuraName)
        -- print('is it a debuff?', isMyAuraActive)
        if (not isMyAuraActive) then
            isMyAuraActive = ConditionerAddOn.BuffExists("player", myActiveAuraName)
        end

        if (not isMyAuraActive) then
            return false
        end
    end

    -- is the aura even active, we let "" pass
    if (not auraName) and (activeAuraName ~= "") then
        if (not Conditions.secondsRemainingBool) and (Conditions.stackConditionalEnum == 0) then
            -- print("FAILED - AURA NOT ACTIVE")
            return false
        end
    end

    -- aura seconds remaining
    if (Conditions.secondsRemainingBool) then
        local rightValue = Conditions.secondsRemainingAmount
        local timeRemaining = math.max((auraExpireTimestamp or 0) - GetTime(), 0)
        if (timeRemaining > rightValue) or ((auraDuration) and (auraDuration == 0)) then
            -- print("FAILED - TOO LONG")
            return false
        elseif (rightValue > 0) and (timeRemaining == 0) then
            -- if rightValue is greater than 0, our timeRemaining must be non-zero too
            return false
        end
    end

    -- stacks
    if (Conditions.stackConditionalEnum > 0) then
        local rightValue = Conditions.stacksAmount
        local leftValue = auraStacks or 0
        local satisfied = ConditionerAddOn:CompareValues(leftValue, Conditions.stackConditionalEnum, rightValue)
        if (not satisfied) then
            -- print("FAILED - STACK CONDITION")
            return false
        end
    end

    -- track another spell's cooldown
    if (Conditions.cooldownRemainingID > 0) then
        -- check this cooldown
        local testFunc = (Conditions.cooldownRemainingIsItemID) and GetItemCooldown or GetSpellCooldown
        local trackedStart, trackedDuration = testFunc(Conditions.cooldownRemainingID)
        -- might use charges
        local numCharges, maxCharges, chargesStart, chargesDuration = GetSpellCharges(Conditions.cooldownRemainingID)
        local rightValue = Conditions.cooldownRemainingAmount
        if (chargesStart) then
            -- some special logic, if 0 then they want to know when numCharges > 0 otherwise, the time before a charge is ready most likely
            if (rightValue == 0) then
                chargesStart = (numCharges > 0) and 0 or chargesStart
            else
                chargesStart = (numCharges == maxCharges) and 0 or chargesStart
            end
            trackedStart, trackedDuration = chargesStart, chargesDuration
        end
        local leftValue = math.max((trackedStart + trackedDuration) - GetTime(), 0)

        local satisfied = ConditionerAddOn:CompareValues(leftValue, Conditions.cooldownRemainingEnum, rightValue)
        if (not satisfied) then
            return false
        end
    end

    -- resource 1
    if (Conditions.resourceTypeEnum > 0) then
        local usePercentage = Conditions.resourceUsePercentageBool
        local rightValue = Conditions.resourceAmount
        local leftValue = 0
        if (Conditions.resourceTypeEnum == (#ConditionerAddOn.Enums.resourceEnum)) then
            leftValue = UnitHealth("player") / ((usePercentage) and UnitHealthMax("player") or 1)
        elseif (Conditions.resourceTypeEnum == (#ConditionerAddOn.Enums.resourceEnum - 1)) then
            leftValue = UnitHealth("target") / ((usePercentage) and UnitHealthMax("target") or 1)
        elseif (Conditions.resourceTypeEnum == (#ConditionerAddOn.Enums.resourceEnum - 2)) then
            leftValue = UnitHealth("pet") / ((usePercentage) and UnitHealthMax("pet") or 1)
        elseif (Conditions.resourceTypeEnum == (#ConditionerAddOn.Enums.resourceEnum - 3)) then
            leftValue = UnitHealth("targettarget") / ((usePercentage) and UnitHealthMax("targettarget") or 1)
        elseif (Conditions.resourceTypeEnum == (#ConditionerAddOn.Enums.resourceEnum - 4)) then
            leftValue = UnitHealth("focus") / ((usePercentage) and UnitHealthMax("focus") or 1)
        elseif (Conditions.resourceTypeEnum == 30) then
            leftValue = UnitHealth(targetUnitToken) / ((usePercentage) and UnitHealthMax(targetUnitToken) or 1)
        elseif (Conditions.resourceTypeEnum == 6) then
            -- runes
            local currentRunes, maxRunes = ConditionerAddOn:GetRunes()
            leftValue = currentRunes / ((usePercentage) and maxRunes or 1)
        else
            leftValue = UnitPower("player", Conditions.resourceTypeEnum - 1) /
                ((usePercentage) and UnitPowerMax("player", Conditions.resourceTypeEnum - 1) or 1)
        end
        leftValue = (usePercentage) and (leftValue * 100) or leftValue
        local satisfied = ConditionerAddOn:CompareValues(leftValue, Conditions.resourceConditionalEnum, rightValue)
        if (not satisfied) then
            -- print("FAILED - RESOURCE 1")
            return false
        end
    end

    -- resource 2
    if (Conditions.alternateResourceTypeEnum > 0) then
        local usePercentage = Conditions.alternateResourceUsePercentageBool
        local rightValue = Conditions.alternateResourceAmount
        local leftValue = 0
        if (Conditions.alternateResourceTypeEnum == (#ConditionerAddOn.Enums.resourceEnum)) then
            leftValue = UnitHealth("player") / ((usePercentage) and UnitHealthMax("player") or 1)
        elseif (Conditions.alternateResourceTypeEnum == (#ConditionerAddOn.Enums.resourceEnum - 1)) then
            leftValue = UnitHealth("target") / ((usePercentage) and UnitHealthMax("target") or 1)
        elseif (Conditions.alternateResourceTypeEnum == (#ConditionerAddOn.Enums.resourceEnum - 2)) then
            leftValue = UnitHealth("pet") / ((usePercentage) and UnitHealthMax("pet") or 1)
        elseif (Conditions.alternateResourceTypeEnum == (#ConditionerAddOn.Enums.resourceEnum - 3)) then
            leftValue = UnitHealth("targettarget") / ((usePercentage) and UnitHealthMax("targettarget") or 1)
        elseif (Conditions.alternateResourceTypeEnum == (#ConditionerAddOn.Enums.resourceEnum - 4)) then
            leftValue = UnitHealth("focus") / ((usePercentage) and UnitHealthMax("focus") or 1)
        elseif (Conditions.alternateResourceTypeEnum == 30) then
            leftValue = UnitHealth(targetUnitToken) / ((usePercentage) and UnitHealthMax(targetUnitToken) or 1)
        elseif (Conditions.alternateResourceTypeEnum == 6) then
            -- runes
            local currentRunes, maxRunes = ConditionerAddOn:GetRunes()
            leftValue = currentRunes / ((usePercentage) and maxRunes or 1)
        else
            leftValue = UnitPower("player", Conditions.alternateResourceTypeEnum - 1) /
                ((usePercentage) and UnitPowerMax("player", Conditions.alternateResourceTypeEnum - 1) or 1)
        end
        leftValue = (usePercentage) and (leftValue * 100) or leftValue
        local satisfied = ConditionerAddOn:CompareValues(leftValue, Conditions.alternateResourceConditionalEnum,
            rightValue)
        if (not satisfied) then
            -- print("FAILED - RESOURCE 2")
            return false
        end
    end

    local finalFunc = (itemID > 0) and GetItemCooldown or GetSpellCooldown
    local finalID = math.max(itemID, spellID)
    local finalStartTime, finalDurationTime = finalFunc(finalID)
    local finalTimeLeft = math.max((finalStartTime + finalDurationTime) - GetTime(), 0)
    local _, itemSpell = GetItemSpell(itemID)
    local _, myGCD = GetSpellBaseCooldown(spellID)
    if (itemID > 0) then
        _, myGCD = GetSpellBaseCooldown(itemSpell)
    end
    myGCD = (myGCD > 0) and (myGCD / 1000) or 1.5
    -- print(myGCD, spellID, itemSpell)
    -- did we make it?
    -- print("WE MADE IT", spellID, finalTimeLeft, myGCD)
    return finalTimeLeft, myGCD, finalStartTime, finalDurationTime, inRange, auraIcon, auraDuration,
        auraExpireTimestamp, isMouseover, isAoe
end

function ConditionerAddOn:GetAvailableTrackingFrame()
    ConditionerAddOn.TrackingFrames = ConditionerAddOn.TrackingFrames or {}
    for k, v in ipairs(ConditionerAddOn.TrackingFrames) do
        if (not v.isActive) then
            return v
        end
    end

    local trackingFrame = ConditionerAddOn:NewTrackingFrame()
    trackingFrame.parentNode = (#ConditionerAddOn.TrackingFrames > 0) and
        ConditionerAddOn.TrackingFrames[#ConditionerAddOn.TrackingFrames] or
        ConditionerAddOn.TrackedFrameDragAnchor
    if (trackingFrame.parentNode == ConditionerAddOn.TrackedFrameDragAnchor) then
        -- I am root
        trackingFrame:SetPoint("CENTER", ConditionerAddOn.TrackedFrameDragAnchor, "CENTER")
    else
        ConditionerAddOn_SavedVariables.Options.AnchorDirection =
            ConditionerAddOn_SavedVariables.Options.AnchorDirection or 0
        if (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 0) then
            trackingFrame:SetPoint("BOTTOMRIGHT", trackingFrame.parentNode, "BOTTOMLEFT", -2, 0)
        elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 1) then
            trackingFrame:SetPoint("BOTTOM", trackingFrame.parentNode, "TOP", 0, 2)
        elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 2) then
            trackingFrame:SetPoint("BOTTOMLEFT", trackingFrame.parentNode, "BOTTOMRIGHT", 2, 0)
        elseif (ConditionerAddOn_SavedVariables.Options.AnchorDirection == 3) then
            trackingFrame:SetPoint("TOP", trackingFrame.parentNode, "BOTTOM", 0, -2)
        end
        trackingFrame.Keybind:SetPoint("RIGHT", trackingFrame, "RIGHT")
    end
    ConditionerAddOn_SavedVariables.Options.TrackedFrameSize =
        ConditionerAddOn_SavedVariables.Options.TrackedFrameSize or 100
    ConditionerAddOn_SavedVariables.Options.TaperSize = ConditionerAddOn_SavedVariables.Options.TaperSize or 80
    local mult = math.pow(ConditionerAddOn_SavedVariables.Options.TaperSize / 100, #ConditionerAddOn.TrackingFrames)
    table.insert(ConditionerAddOn.TrackingFrames, trackingFrame)
    trackingFrame:SetSize(ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * mult,
        ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * mult)
    trackingFrame.Keybind:SetPoint("BOTTOMLEFT", trackingFrame, "BOTTOMLEFT",
        ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * mult * 0.08,
        ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * mult * 0.0325)
    ConditionerAddOn:AddBorder(trackingFrame)
    trackingFrame.Keybind:SetFont("Fonts\\FRIZQT__.TTF",
        math.ceil(0.26 * ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * mult), "OUTLINE, THICK")
    trackingFrame.Countdown.Text:SetFont("Fonts\\FRIZQT__.TTF", math.ceil(
        0.24 * ConditionerAddOn_SavedVariables.Options.TrackedFrameSize * mult), "OUTLINE, THICK")
    return trackingFrame
end

function ConditionerAddOn:GetNextLoadoutSlot()
    local count = 1
    for k, v in pairs(ConditionerAddOn.LoadoutFrame.DropDown.Choices) do
        if (k > 0) then
            count = count + 1
            if (not v) then
                return k
            end
        end
    end

    return count
end

function ConditionerAddOn:FixupLoadoutGaps()
    local totalCount = 0
    local highestIndex = 0
    for k, v in pairs(ConditionerAddOn_SavedVariables_Loadouts) do
        if (k > 0) then
            totalCount = totalCount + 1
            highestIndex = (k > highestIndex) and k or highestIndex
        end
    end

    if (#ConditionerAddOn_SavedVariables_Loadouts ~= totalCount) then
        -- we're uneven, fill in gaps up to highestIndex
        for i = 1, highestIndex do
            ConditionerAddOn_SavedVariables_Loadouts[i] = ConditionerAddOn_SavedVariables_Loadouts[i] or false
        end
    end
end

function ConditionerAddOn:NewCheckBox(parent, label, key)
    local o = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    if (label) then
        o.text = o:CreateFontString(nil, "OVERLAY")
        o.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
        o.text:SetText(label)
        o.text:SetJustifyH("LEFT")
        o.text:SetJustifyV("CENTER")
        o.text:SetTextColor(0, 1, 1, 1)
    end
    o:SetScript("OnEnter", function(self, ...)
        if (o.tooltip) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
            GameTooltip:SetText(o.title or "Conditioner", 0, 0.75, 1)
            GameTooltip:AddLine(o.tooltip, 1, 1, 1, true)
            GameTooltip:SetMinimumWidth(150)
            GameTooltip:Show()
        end
        if (o.demoButton) then
            o.demoButton:SetPoint("BOTTOMRIGHT", GameTooltip, "BOTTOMLEFT")
            o.demoButton:SetPoint("TOPRIGHT", GameTooltip, "TOPLEFT")
            o.demoButton:SetHeight(GameTooltip:GetHeight() * UIParent:GetScale())
            o.demoButton:SetWidth(o.demoButton:GetHeight())
            local currentSpellID, currentItemID = ConditionerAddOn:GetCurrentConditionID()
            local textureToUse = GetItemIcon(currentItemID) or GetSpellTexture(currentSpellID)
            o.demoButton.Texture:SetTexture(textureToUse)
            o.demoButton:Show()
        end
    end)
    o:SetScript("OnLeave", function(self, ...)
        GameTooltip:Hide()
        if (o.demoButton) then
            o.demoButton:Hide()
        end
    end)
    o:SetScript("OnClick", function(self, ...)
        ConditionerAddOn:SetCurrentCondition(key, self:GetChecked())
        if (o.linkedEditBox) and (self:GetChecked()) then
            local editBoxAmount = o.linkedEditBox:GetNumber()
            o.linkedEditBox:SetNumber((editBoxAmount > 100) and 100 or editBoxAmount)
        end
        if (ConditionerAddOn.SharedConditionerFrame) and (ConditionerAddOn.SharedConditionerFrame.EditBoxes) then
            for k, v in pairs(ConditionerAddOn.SharedConditionerFrame.EditBoxes) do
                v:ClearFocus()
            end
        end
        if (not self.filter) and (ConditionerAddOn.SharedConditionerFrame.DispelFilterButton) and
            (ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor) then
            ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:Hide()
        end
        PlaySound(1115)
        ConditionerCloseDropDownMenus()
    end)
    function o:Update()
        self:SetChecked(ConditionerAddOn.CurrentPriorityButton.Conditions[key])
    end

    return o
end

function ConditionerAddOn:SetCurrentCondition(key, value)
    if (ConditionerAddOn.CurrentPriorityButton) then
        ConditionerAddOn.CurrentPriorityButton.Conditions[key] = value
        ConditionerAddOn.CurrentPriorityButton:UpdateKeyBind()
        ConditionerAddOn:StoreCurrentLoadout()
        -- print("SET", key, value)
    end
end

function ConditionerAddOn:GetCurrentConditionValue(key)
    if (ConditionerAddOn.CurrentPriorityButton) then
        return ConditionerAddOn.CurrentPriorityButton.Conditions[key]
    else
        return
    end
end

function ConditionerAddOn:GetCurrentConditionID()
    if (ConditionerAddOn.CurrentPriorityButton) then
        return ConditionerAddOn.CurrentPriorityButton.Data.spellID, ConditionerAddOn.CurrentPriorityButton.Data.itemID
    else
        return
    end
end

function ConditionerAddOn:NewDropDown(title, name, parent, width, choices, key)
    local o = CreateFrame("Frame", name, parent, "ConditionerUIDropDownMenuTemplate")
    if (title) then
        o.text = o:CreateFontString(nil, "OVERLAY", "SystemFont_NamePlateCastBar")
        o.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
        o.text:SetPoint("BOTTOM", o, "TOP", 0, -12)
        o.text:SetText(title)
        o.text:SetJustifyH("CENTER")
        o.text:SetJustifyV("CENTER")
        o.text:SetTextColor(0, 1, 1, 1)
        o.text:SetSize(150, o:GetHeight())
    end
    CONDITIONERDROPDOWNMENU_SetWidth(o, width)
    function o:Update()
        local text = choices[ConditionerAddOn.CurrentPriorityButton.Conditions[key]]
        if (ConditionerAddOn.CurrentPriorityButton.Conditions[key] == 0) then
            text = string.format("|cffd742f4%s|r", text)
        end
        CONDITIONERDROPDOWNMENU_SetText(o, text)
        CONDITIONERDROPDOWNMENU_Initialize(o, function(self, level, menuList)
            if (ConditionerAddOn.SharedConditionerFrame) and (ConditionerAddOn.SharedConditionerFrame.EditBoxes) then
                for k, v in pairs(ConditionerAddOn.SharedConditionerFrame.EditBoxes) do
                    v:ClearFocus()
                end
                if (ConditionerAddOn.SharedConditionerFrame.DispelFilterButton) and
                    (ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor) then
                    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:Hide()
                end
            end

            local info = CONDITIONERDROPDOWNMENU_CreateInfo()

            for i = 0, #choices do
                if (key == "alternateResourceTypeEnum" or key == "resourceTypeEnum") then
                    local usableResources = ConditionerAddOn:GetUsableResources()
                    if (usableResources[i]) or (i == 0) or (i > 29) then
                        info.text = choices[i]
                        info.func = self.SetValue
                        info.arg1 = i
                        info.checked = (i == ConditionerAddOn.CurrentPriorityButton.Conditions[key])
                        CONDITIONERDROPDOWNMENU_AddButton(info)
                    end
                elseif (key == "shapeShiftEnum") then
                    local validShapeshift = ConditionerAddOn:IsValidShapeshift(i)
                    if (validShapeshift) then
                        info.text = choices[i]
                        info.func = self.SetValue
                        info.arg1 = i
                        info.checked = (i == ConditionerAddOn.CurrentPriorityButton.Conditions[key])
                        CONDITIONERDROPDOWNMENU_AddButton(info)
                    end
                else
                    info.text = choices[i]
                    info.func = self.SetValue
                    info.arg1 = i
                    info.checked = (i == ConditionerAddOn.CurrentPriorityButton.Conditions[key])
                    CONDITIONERDROPDOWNMENU_AddButton(info)
                end
            end
        end)
    end

    function o:SetValue(newValue)
        o.CurrentValue = newValue
        ConditionerAddOn:SetCurrentCondition(key, newValue)
        local text = choices[newValue]
        if (newValue == 0) then
            text = string.format("|cffd742f4%s|r", choices[newValue])
        end
        CONDITIONERDROPDOWNMENU_SetText(o, text)
        ConditionerCloseDropDownMenus()
    end

    return o
end

function ConditionerAddOn:NewConditionsWindow(parent)
    local o = CreateFrame("Button", nil, parent, "ConditionerButtonTemplate")
    o:SetPoint("LEFT", parent, "RIGHT")
    o:SetSize(32, 32)
    o:SetText("+")
    o:SetScript("OnEnter", function(self, ...)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 0)
        GameTooltip:SetText("Conditioner", 0, 0.75, 1)
        GameTooltip:AddLine("Click to view conditions.", 1, 1, 1, true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    o:SetScript("OnLeave", function(self, ...)
        GameTooltip:Hide()
    end)
    o:SetScript("OnClick", function(self)
        PlaySound(1115)
        for k, v in pairs(ConditionerAddOn.SharedConditionerFrame.EditBoxes) do
            v:ClearFocus()
        end
        if (ConditionerAddOn.CurrentPriorityButton) then
            if (ConditionerAddOn.CurrentPriorityButton == parent) then
                if (ConditionerAddOn.SharedConditionerFrame:IsShown()) then
                    ConditionerAddOn.SharedConditionerFrame:Hide()
                    -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
                else
                    ConditionerAddOn.SharedConditionerFrame:Hide()
                    ConditionerAddOn.SharedConditionerFrame:Show()
                    -- ActionButton_ShowOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
                end
            else
                -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
                ConditionerAddOn.CurrentPriorityButton = parent
                ConditionerAddOn.SharedConditionerFrame:Hide()
                ConditionerAddOn.SharedConditionerFrame:Show()
                -- ActionButton_ShowOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
            end
        else
            ConditionerAddOn.CurrentPriorityButton = parent
            ConditionerAddOn.SharedConditionerFrame:Hide()
            ConditionerAddOn.SharedConditionerFrame:Show()
            -- ActionButton_ShowOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
        end
        local titleString = ""
        if (parent.Data.itemID > 0) then
            titleString = GetItemInfo(parent.Data.itemID)
        else
            titleString = GetSpellInfo(parent.Data.spellID)
        end
        ConditionerAddOn.SharedConditionerFrame.Background.Title:SetText(titleString)
        ConditionerAddOn.SharedConditionerFrame:SetClampRectInsets(0, 0, 0, -ConditionerAddOn.SharedConditionerFrame
            .Background:GetHeight() or 0)
        ConditionerAddOn.SharedConditionerFrame:SetPoint("CENTER", self, "BOTTOMRIGHT")
        for k, v in pairs(ConditionerAddOn.SharedConditionerFrame.DropDowns) do
            v:Update()
        end
        for k, v in pairs(ConditionerAddOn.SharedConditionerFrame.EditBoxes) do
            v:Update()
        end
        for k, v in pairs(ConditionerAddOn.SharedConditionerFrame.CheckBoxes) do
            v:Update()
        end
        ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:UpdateIcon()
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:Hide()
        if (ConditionerAddOn.LoadoutFrame) then
            ConditionerAddOn.LoadoutFrame.InputName:Hide()
            ConditionerAddOn.LoadoutFrame.ImportExport:Hide()
        end
    end)
end

function ConditionerAddOn:NewPriorityButton(isPrimary)
    local o = CreateFrame("Button", nil, SpellBookFrame)
    o:SetSize(40, 40)
    o.icon = o:CreateTexture()
    o.icon:SetAllPoints(o)
    o.icon:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")
    o.icon:SetDrawLayer("BACKGROUND")
    o.Border = CreateFrame("Frame", nil, o, BackdropTemplateMixin and "BackdropTemplate")
    o.Border:SetBackdrop({
        edgeFile = "Interface\\GLUES\\COMMON\\Glue-Tooltip-Border",
        edgeSize = 16
    })
    o.Border:SetPoint("TOPRIGHT", o, "TOPRIGHT", 4, 4)
    o.Border:SetPoint("BOTTOMLEFT", o, "BOTTOMLEFT", -8, -8)
    o.Border:ApplyBackdrop()
    o.texture = o:CreateTexture()
    o.texture:Hide()
    o.texture:SetAllPoints(o)
    o.texture:SetBlendMode("ADD")
    o.texture:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    if (isPrimary) then
        o:SetPoint("TOPLEFT", SpellBookFrame, "TOPRIGHT", 50, 0)
        o.Text = o:CreateFontString(nil, "OVERLAY")
        o.Text:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE, THICK")
        o.Text:SetPoint("CENTER", o, "CENTER", 1, 0)
        o.Text:SetTextColor(0, 1, 1)
        o.Text:SetText("+")
        o.Text:SetJustifyH("CENTER")
        o.Text:SetJustifyV("MIDDLE")
        -- menu button
        o.MenuButton = CreateFrame("Button", nil, o, "ConditionerButtonTemplate")
        o.MenuButton:SetPoint("BOTTOM", o, "TOP")
        o.MenuButton:SetSize(55, 32)
        o.MenuButton:SetText("Menu")
        o.MenuButton:SetScript("OnClick", function(self)
            if (ConditionerAddOn.LoadoutFrame:IsShown()) then
                ConditionerAddOn.LoadoutFrame:Hide()
            else
                ConditionerAddOn.LoadoutFrame:Show()
            end
            PlaySound(1115)
        end)
        o:SetScript("OnHide", function(self, delta)
            ConditionerAddOn.numToHide = 0
            ConditionerAddOn:ScrollPriorityButtons(ConditionerAddOn.numToHide)
        end)
        o:SetScript("OnShow", function(self, delta)
            ConditionerAddOn.numToHide = 0
            ConditionerAddOn:ScrollPriorityButtons(ConditionerAddOn.numToHide)
        end)
    else
        o.Text = o:CreateFontString(nil, "OVERLAY")
        o.Text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
        o.Text:SetPoint("BOTTOMLEFT", o, "BOTTOMLEFT", 2, 2)
        o.Text:SetPoint("RIGHT", o, "RIGHT")
        o.Text:SetTextColor(1, 1, 1)
        o.Text:SetWordWrap(false)
        o.Text:SetJustifyH("LEFT")
        o.Text:SetJustifyV("BOTTOM")
        o.CurrentTexture = 0
        o.Data = {
            spellID = 0,
            itemID = 0
        }
        o.Conditions = {
            -- strings
            activeAuraString = "",
            keyBindingString = "",
            myActiveAura = "",
            -- bools
            secondsRemainingBool = false,
            isInterruptBool = false,
            resourceUsePercentageBool = false,
            alternateResourceUsePercentageBool = false,
            onlyWhenReadyBool = false,
            highlightOnlyBool = false,
            buffBool = false,
            debuffBool = false,
            magicBool = false,
            curseBool = false,
            poisonBool = false,
            diseaseBool = false,
            -- boolShort
            cooldownRemainingIsItemID = false,
            onlyInRange = false,
            onlyDuringCC = false,
            canCast = false,
            hideWhileCasting = false,
            showInAoeRotation = false,
            -- enums
            resourceTypeEnum = 0,
            resourceConditionalEnum = 0,
            alternateResourceTypeEnum = 0,
            alternateResourceConditionalEnum = 0,
            auraTargetEnum = 0,
            stackConditionalEnum = 0,
            chargesConditionalEnum = 0,
            shapeShiftEnum = 0,
            cooldownRemainingEnum = 0,
            -- amounts
            stacksAmount = 0,
            secondsRemainingAmount = 0,
            resourceAmount = 0,
            alternateResourceAmount = 0,
            chargesAmount = 0,
            cooldownRemainingID = 0,
            cooldownRemainingAmount = 0
        }
        function o:UpdateTexture()
            o.CurrentTexture = GetItemIcon(o.Data.itemID) or GetSpellTexture(o.Data.spellID) or 0
            if (o.CurrentTexture > 0) then
                o.icon:SetTexture(o.CurrentTexture)
            else
                o.icon:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")
            end
            o.Text:SetText(o.Conditions.keyBindingString)
        end

        function o:UpdateKeyBind()
            o.Text:SetText(o.Conditions.keyBindingString)
        end

        o.ToggleConditions = ConditionerAddOn:NewConditionsWindow(o)
    end
    o:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    o:SetScript("OnEnter", function(self)
        o.texture:Show()
        GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
        if (o.Data) then
            if (o.Data.itemID ~= 0) then
                GameTooltip:SetItemByID(o.Data.itemID)
            else
                GameTooltip:SetSpellByID(o.Data.spellID)
            end
            GameTooltip:AddLine(string.format("\n%s : %s", (o.Data.itemID ~= 0) and "Item ID" or "Spell ID",
                (o.Data.itemID ~= 0) and o.Data.itemID or o.Data.spellID), 0, 0.75, 1, true)
            GameTooltip:AddLine("\nMouse Wheel - Scroll Priority List", 1, 0.4, 1, true)
            GameTooltip:AddLine(string.format("Left Click - Pick Up %s", (o.Data.itemID ~= 0) and "Item" or "Spell"), 1,
                0.4, 1, true)
            GameTooltip:AddLine(string.format("Right Click - Remove %s From List",
                (o.Data.itemID ~= 0) and "Item" or "Spell"), 1, 0.4, 1, true)
            GameTooltip:SetMinimumWidth(150)
            GameTooltip:Show()
        else
            GameTooltip:SetText("Conditioner", 0, 0.75, 1)
            GameTooltip:AddLine(
                "Drag and drop spells or items here to begin creating rotations!\n\n|cffFFff00You MUST save a rotation in the loadout menu in order for it to persist.|r"
                ,
                1, 1, 1, true)
            GameTooltip:AddLine("\nMouse Wheel - Scroll Priority List", 1, 0.4, 1, true)
            GameTooltip:AddLine("Right Click - Scroll Priority List To Top", 1, 0.4, 1, true)
            GameTooltip:SetMinimumWidth(150)
            GameTooltip:Show()
        end
    end)
    o:SetScript("OnLeave", function(self)
        o.texture:Hide()
        GameTooltip:Hide()
    end)
    o:SetScript("OnClick", function(self, button, down)
        if (not down) then
            ConditionerAddOn:PriorityClickHandler(self, button)
        end
        if (isPrimary) and (not down) and (button == "RightButton") then
            ConditionerAddOn.numToHide = 0
            ConditionerAddOn:ScrollPriorityButtons(ConditionerAddOn.numToHide)
        end
        PlaySound(1202)
    end)
    o:SetScript("OnMouseWheel", function(self, delta)
        ConditionerAddOn.numToHide = math.min(#ConditionerAddOn.PriorityButtons,
            math.max((ConditionerAddOn.numToHide or 0) - delta, 0))
        ConditionerAddOn:ScrollPriorityButtons(ConditionerAddOn.numToHide)
    end)
    return o
end

function ConditionerAddOn:GetLoadoutPackageByID(loadoutID)
    if (loadoutID) then
        -- get default if -1
        if (loadoutID == -1) then
            local currentSpecID = ConditionerGetSpecialization()
            if (currentSpecID) then
                local currentSpec = ConditionerGetSpecializationInfo(currentSpecID)
                local basicLoadString = ConditionerAddOn.DefaultLoadouts[currentSpec]
                if (basicLoadString) then
                    local basicPackage = {
                        name = "Basic Rotation",
                        value = basicLoadString,
                        spec = currentSpec
                    }
                    return basicPackage
                else
                    return
                end
            end
        else
            local currentSpecID = ConditionerGetSpecialization()
            if (currentSpecID) then
                local currentSpec = ConditionerGetSpecializationInfo(currentSpecID)
                if (ConditionerAddOn_SavedVariables_Loadouts[loadoutID]) and
                    (ConditionerAddOn_SavedVariables_Loadouts[loadoutID].spec == currentSpec) then
                    return ConditionerAddOn_SavedVariables_Loadouts[loadoutID]
                else
                    return ConditionerAddOn_SavedVariables_Loadouts[0]
                end
            end
        end
    else
        local currentSpecID = ConditionerGetSpecialization()
        if (currentSpecID) then
            local currentSpec = ConditionerGetSpecializationInfo(currentSpecID)
            local packageID = ConditionerAddOn_SavedVariables.CurrentLoadouts[currentSpec] or 0
            if (packageID) then
                if (packageID == -1) then
                    local basicLoadString = ConditionerAddOn.DefaultLoadouts[currentSpec]
                    if (basicLoadString) then
                        local basicPackage = {
                            name = "Basic Rotation",
                            value = basicLoadString,
                            spec = currentSpec
                        }
                        return basicPackage
                    else
                        return
                    end
                else
                    if (ConditionerAddOn_SavedVariables_Loadouts[packageID]) and
                        (ConditionerAddOn_SavedVariables_Loadouts[packageID].spec == currentSpec) then
                        return ConditionerAddOn_SavedVariables_Loadouts[packageID]
                    else
                        return ConditionerAddOn_SavedVariables_Loadouts[0]
                    end
                end
            end
        end
    end
end

function ConditionerAddOn:ClearCurrentLoadout()
    for k, v in ipairs(ConditionerAddOn.PriorityButtons) do
        ConditionerAddOn:SetConditions(v)
    end
end

function ConditionerAddOn:LoadoutIsDirty()
    if (ConditionerAddOn.LoadoutFrame) then
        local currentLoadoutString = ConditionerAddOn:CreateLoadoutString()
        local currentSelected = ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice or 0
        local selectedPackage = ConditionerAddOn:GetLoadoutPackageByID(currentSelected)
        if (currentLoadoutString and selectedPackage) then
            return (currentSelected > 0) and (currentLoadoutString ~= selectedPackage.value) or false
        else
            return false
        end
    end
end

function ConditionerAddOn:CreateLoadoutString(withoutKeybinds)
    local loadoutString = ""
    local results = 0
    for k, v in ipairs(ConditionerAddOn.PriorityButtons) do
        if (v.Data.spellID + v.Data.itemID > 0) then
            local conditions = ConditionerAddOn:GetConditions(v, withoutKeybinds)
            loadoutString = (results == 0) and string.format("%s", conditions) or
                string.format("%s\n%s", loadoutString, conditions)
            results = results + 1
        end
    end
    return (results > 0) and loadoutString or false
end

function ConditionerAddOn:UnsavedChanges(frame, shouldHide)
    if (not ConditionerAddOn.WarningInfoBoxUnsaved) then
        ConditionerAddOn.WarningInfoBoxUnsaved = CreateFrame("Frame", nil, ConditionerAddOn.LoadoutFrame)
        ConditionerAddOn.WarningInfoBoxUnsaved:SetFrameLevel(UIParent:GetFrameLevel() + 10)
        ConditionerAddOn.WarningInfoBoxUnsaved:Hide()
        ConditionerAddOn:AddBorder(ConditionerAddOn.WarningInfoBoxUnsaved)
        ConditionerAddOn.WarningInfoBoxUnsaved.Texture = ConditionerAddOn.WarningInfoBoxUnsaved:CreateTexture()
        ConditionerAddOn.WarningInfoBoxUnsaved.Texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        ConditionerAddOn.WarningInfoBoxUnsaved.Texture:SetAllPoints(ConditionerAddOn.WarningInfoBoxUnsaved)
        ConditionerAddOn.WarningInfoBoxUnsaved.Text = ConditionerAddOn.WarningInfoBoxUnsaved:CreateFontString(nil,
            "OVERLAY", "SystemFont_Huge1_Outline")
        ConditionerAddOn.WarningInfoBoxUnsaved.Text:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE, THICK")
        ConditionerAddOn.WarningInfoBoxUnsaved.Text:SetAllPoints(ConditionerAddOn.WarningInfoBoxUnsaved)
        ConditionerAddOn.WarningInfoBoxUnsaved.Text:SetTextColor(1, 1, 0, 1)
        ConditionerAddOn.WarningInfoBoxUnsaved.Text:SetText("You have\nunsaved changes\nin your rotation!")
        ConditionerAddOn.WarningInfoBoxUnsaved:SetSize(ConditionerAddOn.WarningInfoBoxUnsaved.Text:GetStringWidth() *
            1.25,
            ConditionerAddOn.WarningInfoBoxUnsaved.Text:GetStringHeight() * 1.25)
    end

    if (shouldHide) then
        ConditionerAddOn.WarningInfoBoxUnsaved:Hide()
    else
        ConditionerAddOn.WarningInfoBoxUnsaved:ClearAllPoints()
        ConditionerAddOn.WarningInfoBoxUnsaved:SetPoint("TOP", frame, "BOTTOM")
        ConditionerAddOn.WarningInfoBoxUnsaved:Show()
    end
end

function ConditionerAddOn:WarningCreateNewLoadout(frame, shouldHide)
    if (not ConditionerAddOn.WarningInfoBoxCreateNew) then
        ConditionerAddOn.WarningInfoBoxCreateNew = CreateFrame("Frame", nil, ConditionerAddOn.LoadoutFrame)
        ConditionerAddOn.WarningInfoBoxCreateNew:SetFrameLevel(UIParent:GetFrameLevel() + 10)
        ConditionerAddOn.WarningInfoBoxCreateNew:Hide()
        ConditionerAddOn:AddBorder(ConditionerAddOn.WarningInfoBoxCreateNew)
        ConditionerAddOn.WarningInfoBoxCreateNew.Texture = ConditionerAddOn.WarningInfoBoxCreateNew:CreateTexture()
        ConditionerAddOn.WarningInfoBoxCreateNew.Texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
        ConditionerAddOn.WarningInfoBoxCreateNew.Texture:SetAllPoints(ConditionerAddOn.WarningInfoBoxCreateNew)
        ConditionerAddOn.WarningInfoBoxCreateNew.Text = ConditionerAddOn.WarningInfoBoxCreateNew:CreateFontString(nil,
            "OVERLAY", "SystemFont_Huge1_Outline")
        ConditionerAddOn.WarningInfoBoxCreateNew.Text:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE, THICK")
        ConditionerAddOn.WarningInfoBoxCreateNew.Text:SetAllPoints(ConditionerAddOn.WarningInfoBoxCreateNew)
        ConditionerAddOn.WarningInfoBoxCreateNew.Text:SetTextColor(1, 1, 0, 1)
        ConditionerAddOn.WarningInfoBoxCreateNew.Text:SetText("You must create\na new loadout!")
        ConditionerAddOn.WarningInfoBoxCreateNew:SetSize(
            ConditionerAddOn.WarningInfoBoxCreateNew.Text:GetStringWidth() * 1.25,
            ConditionerAddOn.WarningInfoBoxCreateNew.Text:GetStringHeight() * 1.5)
    end

    if (shouldHide) then
        ConditionerAddOn.WarningInfoBoxCreateNew:Hide()
    else
        ConditionerAddOn.WarningInfoBoxCreateNew:ClearAllPoints()
        ConditionerAddOn.WarningInfoBoxCreateNew:SetPoint("TOP", frame, "BOTTOM")
        ConditionerAddOn.WarningInfoBoxCreateNew:Show()
    end
end

function ConditionerAddOn:StoreCurrentLoadout()
    local currentSpecID = ConditionerGetSpecialization()
    if (currentSpecID) then
        local currentSpec = ConditionerGetSpecializationInfo(currentSpecID)
        ConditionerAddOn_SavedVariables.CurrentLoadouts[currentSpec] =
            ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice or 0
        if (ConditionerAddOn:LoadoutIsDirty()) then
            ConditionerAddOn.LoadoutFrame.OverWrite:Enable()
            if (ConditionerAddOn.LoadoutFrame) then
                ConditionerAddOn.LoadoutFrame:Show()
            end
            ConditionerAddOn.LoadoutFrame.OverWrite:LockHighlight()
            ConditionerAddOn.LoadoutFrame.OverWrite:SetText("Save")
            ConditionerAddOn:UnsavedChanges(ConditionerAddOn.LoadoutFrame.OverWrite)
        else
            ConditionerAddOn.LoadoutFrame.OverWrite:Disable()
            ConditionerAddOn.LoadoutFrame.OverWrite:UnlockHighlight()
            ConditionerAddOn.LoadoutFrame.OverWrite:SetText("Saved")
            ConditionerAddOn:UnsavedChanges(nil, true)
        end
    end
end

function ConditionerAddOn:ApplyLoadout(loadoutPackage, fromString)
    local loadoutString = fromString or ((loadoutPackage) and loadoutPackage.value or false)
    if (not loadoutString) then
        return
    end
    local conditions = {}
    for conditionString in loadoutString:gmatch("(%[.-])") do
        table.insert(conditions, conditionString)
    end
    for k, v in ipairs(conditions) do
        local freeButton = ConditionerAddOn:GetNextPriorityButton()
        ConditionerAddOn:SetConditions(freeButton, v)
    end
    ConditionerAddOn:CollapsePriorityButtons()
    ConditionerAddOn.numToHide = 0
    ConditionerAddOn:ScrollPriorityButtons(ConditionerAddOn.numToHide)
end

-- ============================================================================================================================--
-----------------------------------------------------------INITIALIZE-----------------------------------------------------------
-- ============================================================================================================================--
function ConditionerAddOn:Init()
    ConditionerAddOn:TooltipScrubber()
    ConditionerAddOn.MainButton = ConditionerAddOn:NewPriorityButton(true)
    ConditionerAddOn.PriorityButtons = {}
    ConditionerAddOn.HighlightDemoButton = CreateFrame("Frame")
    ConditionerAddOn.HighlightDemoButton.Texture = ConditionerAddOn.HighlightDemoButton:CreateTexture()
    ConditionerAddOn.HighlightDemoButton.Texture:SetAllPoints(ConditionerAddOn.HighlightDemoButton)
    ConditionerAddOn.HighlightDemoButton:SetFrameStrata("HIGH")
    ConditionerAddOn:AddBorder(ConditionerAddOn.HighlightDemoButton)
    ConditionerAddOn.HighlightDemoButton:Hide()
    ConditionerAddOn.HighlightDemoButton:SetScript("OnUpdate", function(self, elapsed)
        ConditionerAddOn.HighlightDemoButton.timer = (ConditionerAddOn.HighlightDemoButton.timer or 0) + elapsed
        if (ConditionerAddOn.HighlightDemoButton.timer > 0.5) then
            ConditionerAddOn.HighlightDemoButton.toggle = not ConditionerAddOn.HighlightDemoButton.toggle
            if (ConditionerAddOn.HighlightDemoButton.toggle) then
                ActionButton_ShowOverlayGlow(ConditionerAddOn.HighlightDemoButton)
                ConditionerAddOn.HighlightDemoButton.timer = -3
            else
                ActionButton_HideOverlayGlow(ConditionerAddOn.HighlightDemoButton)
                ConditionerAddOn.HighlightDemoButton.timer = -2
            end
        end
    end)
    -- ==================================================================================================--
    --------------------------------------MAIN TRACKING FRAME ANCHOR--------------------------------------
    -- ==================================================================================================--
    ConditionerAddOn.TrackedFrameDragAnchor = CreateFrame("Frame", nil, SpellBookFrame)
    ConditionerAddOn.TrackedFrameDragAnchor.x = ConditionerAddOn_SavedVariables.Options.TrackedFrameAnchorCoords.x or
        UIParent:GetWidth() / 2
    ConditionerAddOn.TrackedFrameDragAnchor.y = ConditionerAddOn_SavedVariables.Options.TrackedFrameAnchorCoords.y or
        UIParent:GetHeight() / 2
    ConditionerAddOn.TrackedFrameDragAnchor:SetFrameStrata("HIGH")
    ConditionerAddOn.TrackedFrameDragAnchor:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
        ConditionerAddOn.TrackedFrameDragAnchor.x, ConditionerAddOn.TrackedFrameDragAnchor.y)
    ConditionerAddOn.TrackedFrameDragAnchor:SetSize(64, 64)
    ConditionerAddOn.TrackedFrameDragAnchor.Texture = ConditionerAddOn.TrackedFrameDragAnchor:CreateTexture()
    ConditionerAddOn.TrackedFrameDragAnchor.Texture:SetAllPoints(ConditionerAddOn.TrackedFrameDragAnchor)
    ConditionerAddOn.TrackedFrameDragAnchor.Texture:SetDrawLayer("BACKGROUND")
    SetPortraitToTexture(ConditionerAddOn.TrackedFrameDragAnchor.Texture,
        "Interface\\DialogFrame\\UI-DialogBox-Background")
    ConditionerAddOn.TrackedFrameDragAnchor.Text = ConditionerAddOn.TrackedFrameDragAnchor:CreateFontString(nil,
        "OVERLAY", "SystemFont_NamePlateCastBar")
    ConditionerAddOn.TrackedFrameDragAnchor.Text:SetPoint("CENTER", ConditionerAddOn.TrackedFrameDragAnchor, "CENTER")
    ConditionerAddOn.TrackedFrameDragAnchor.Text:SetTextColor(0, 1, 1, 1)
    ConditionerAddOn.TrackedFrameDragAnchor.Text:SetText("Tracked\nFrame\nAnchor")
    ConditionerAddOn.TrackedFrameDragAnchor:EnableMouse(true)
    ConditionerAddOn.TrackedFrameDragAnchor:RegisterForDrag("LeftButton")
    ConditionerAddOn.TrackedFrameDragAnchor:SetMovable(true)
    ConditionerAddOn.TrackedFrameDragAnchor:SetClampedToScreen(true)
    ConditionerAddOn.TrackedFrameDragAnchor:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    ConditionerAddOn.TrackedFrameDragAnchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local left, bottom, width, height = self:GetRect()
        ConditionerAddOn_SavedVariables.Options.TrackedFrameAnchorCoords.x = (left + width / 2)
        ConditionerAddOn_SavedVariables.Options.TrackedFrameAnchorCoords.y = (bottom + height / 2)
    end)

    ConditionerAddOn.TrackedFrameDragAnchor:SetScript("OnMouseUp", function(self, button)
        if (button == "RightButton") then
            ConditionerAddOn_SavedVariables.Options.AnchorDirection =
                (ConditionerAddOn_SavedVariables.Options.AnchorDirection + 1) % 4
            ConditionerAddOn:UpdateTrackerPoints()
        end
    end)
    ConditionerAddOn.TrackedFrameDragAnchor:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetText("Conditioner", 0, 0.75, 1)
        GameTooltip:AddLine("Left Click - Drag Anchor\nRight Click - Rotate Tail\nMouse Wheel - Resize Frames", 1, 1, 1,
            true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.TrackedFrameDragAnchor:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    ConditionerAddOn.TrackedFrameDragAnchor:SetScript("OnMouseWheel", function(self, delta)
        ConditionerAddOn_SavedVariables.Options.TrackedFrameSize = math.max(50, math.min(
            (ConditionerAddOn_SavedVariables.Options.TrackedFrameSize or 100) + delta * 20, 300))
        ConditionerAddOn:ResizeTrackers()
    end)

    ConditionerAddOn.TrackedFrameDragAnchor.MainHand = ConditionerAddOn:CreateSwingFrame("Main Hand", UIParent, 0, 0.75,
        1)
    ConditionerAddOn.TrackedFrameDragAnchor.OffHand = ConditionerAddOn:CreateSwingFrame("Off Hand",
        ConditionerAddOn.TrackedFrameDragAnchor.MainHand, 1, 0, 1)
    ConditionerAddOn.TrackedFrameDragAnchor.MainHand:SetSize(100, 10)
    ConditionerAddOn.TrackedFrameDragAnchor.OffHand:SetSize(100, 10)

    ConditionerAddOn.TrackedFrameDragAnchor.Ranged = ConditionerAddOn:CreateSwingFrame("Ranged", UIParent, 0.5, 0,
        0.5)
    ConditionerAddOn.TrackedFrameDragAnchor.Ranged:SetSize(100, 10)

    -- always set main/offhand/ranged together
    ConditionerAddOn.TrackedFrameDragAnchor.OffHand:SetPoint("TOPLEFT", ConditionerAddOn.TrackedFrameDragAnchor.MainHand,
        "BOTTOMLEFT")
    ConditionerAddOn.TrackedFrameDragAnchor.Ranged:SetPoint("TOPLEFT", ConditionerAddOn.TrackedFrameDragAnchor.OffHand,
        "BOTTOMLEFT")

    ConditionerAddOn.TrackedFrameDragAnchor.RangedCast = ConditionerAddOn:CreateSwingFrame("",
        ConditionerAddOn.TrackedFrameDragAnchor.Ranged, 0, 1,
        0)
    ConditionerAddOn.TrackedFrameDragAnchor.RangedCast:SetPoint("BOTTOMLEFT", ConditionerAddOn.TrackedFrameDragAnchor
        .Ranged, "BOTTOMLEFT")
    ConditionerAddOn.TrackedFrameDragAnchor.RangedCast:SetSize(1, 2)


    -- can piggyback to make casting bar
    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar = ConditionerAddOn:CreateSwingFrame("CASTBAR", UIParent, 1, 1,
        0.25)
    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:SetSize(1, 10)
    ConditionerAddOn.TrackedFrameDragAnchor.CastingBar.Timer =
        ConditionerAddOn.TrackedFrameDragAnchor.CastingBar:CreateFontString(nil, "OVERLAY", "SystemFont_Huge1_Outline")

    -- ==================================================================================================--
    --------------------------------------MAIN TRACKING FRAME ANCHOR--------------------------------------
    -- ==================================================================================================--
    ConditionerAddOn.SharedConditionerFrame = CreateFrame("Frame", nil, SpellBookFrame)
    ConditionerAddOn.SharedConditionerFrame:SetFrameStrata("MEDIUM")
    ConditionerAddOn.SharedConditionerFrame:SetClampedToScreen(true)
    ConditionerAddOn.SharedConditionerFrame:SetSize(10, 10)
    ConditionerAddOn.SharedConditionerFrame.Background = CreateFrame("Frame", nil,
        ConditionerAddOn.SharedConditionerFrame)
    ConditionerAddOn.SharedConditionerFrame.Background.Texture =
        ConditionerAddOn.SharedConditionerFrame.Background:CreateTexture()
    ConditionerAddOn.SharedConditionerFrame.Background.Texture:SetAllPoints(
        ConditionerAddOn.SharedConditionerFrame.Background)
    ConditionerAddOn.SharedConditionerFrame.Background.Texture:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
    ConditionerAddOn.SharedConditionerFrame.Background:SetFrameStrata("BACKGROUND")
    ConditionerAddOn.SharedConditionerFrame.Background.Texture:SetDrawLayer("BACKGROUND")
    ConditionerAddOn.SharedConditionerFrame.Background:SetScript("OnShow", function(self)
        C_Timer.After(0.01, function()
            local leftA, bottomA, widthA, heightA = ConditionerAddOn.SharedConditionerFrame.Background:GetRect()
            local leftB, bottomB, widthB, heightB = ConditionerAddOn.TrackedFrameDragAnchor:GetRect()
            local leftC, bottomC, widthC, heightC = ConditionerAddOn.AoeRotation:GetRect()
            if (leftA) and (leftB) and (leftA <= (leftB + widthB)) and (leftB <= (leftA + widthA)) and
                (bottomA <= (bottomB + heightB)) and (bottomB <= (bottomA + heightA)) then
                ConditionerAddOn.TrackedFrameDragAnchor:Hide()
            end
            -- for aoe tracked frame
            if (leftA) and (leftC) and (leftA <= (leftC + widthC)) and (leftC <= (leftA + widthA)) and
                (bottomA <= (bottomC + heightC)) and (bottomC <= (bottomA + heightA)) then
                ConditionerAddOn.AoeRotation:Hide()
            end
        end)
    end)
    ConditionerAddOn.SharedConditionerFrame.Background:SetScript("OnHide", function(self)
        ConditionerAddOn.TrackedFrameDragAnchor:Show()
        ConditionerAddOn.AoeRotation:Show()
    end)
    -- stance things
    function ConditionerAddOn:GetShapeshiftName(index)
        if (GetShapeshiftFormInfo) then
            local icon, active, castable, spellId = GetShapeshiftFormInfo(index)
            if (spellId) then
                local spellName, _ = GetSpellInfo(spellId)
                return spellName
            end
        end

        return ""
    end

    local stance1 = ConditionerAddOn:GetShapeshiftName(1)
    local stance2 = ConditionerAddOn:GetShapeshiftName(2)
    local stance3 = ConditionerAddOn:GetShapeshiftName(3)
    local stance4 = ConditionerAddOn:GetShapeshiftName(4)
    local stance5 = ConditionerAddOn:GetShapeshiftName(5)
    local stance6 = ConditionerAddOn:GetShapeshiftName(6)
    local stance7 = ConditionerAddOn:GetShapeshiftName(7)

    ConditionerAddOn.Enums = {
        resourceEnum = {
            [0] = "Select a Resource Type",
            "Mana",
            "Rage",
            "Focus",
            "Energy",
            "Combo Points",
            "Runes",
            "Runic Power",
            "Soul Shards",
            "Lunar Power",
            "Holy Power",
            "Alternate",
            "Maelstrom",
            "Chi",
            "Insanity",
            "Combo Points", -- old combo points
            "Obsolete2",
            "Arcane Charges",
            "Fury",
            "Pain",
            "Essence",
            "Placeholder",               -- 21
            "Placeholder",               -- 22
            "Placeholder",               -- 23
            "Placeholder",               -- 24
            "Placeholder",               -- 25
            "Placeholder",               -- 26
            "Placeholder",               -- 27
            "Placeholder",               -- 28
            "Placeholder",               -- 29
            "Target Unit's Health",      -- 30
            "Focus Target's Health",     -- 31
            "Target of Target's Health", -- 32
            "My Pet's Health",           -- 33
            "Target's Health",           -- 34
            "My Health"                  -- 35
        },
        conditionalOperatorEnum = {
            [0] = "Choose Operator",
            ">",
            ">=",
            "==",
            "<=",
            "<",
            "~="
        },
        auraTargetChoicesEnum = {
            [0] = "Choose a Target",
            "Me",
            "Enemy Target",
            "Friendly Target",
            "Any Target",
            "Enemy MouseOver", -- 5
            "Friendly MouseOver",
            "Any MouseOver",
            "My Pet",
            "My Pet's Target",
            "My Focus", -- 10
            "My Focus' Target",
            "My Target's Target",
            "Friendly Player",
            "Enemy Player",
            "Any Player", -- 15
            "Soft - Any Enemy",
            "Soft - Any Friend",
            "Soft - Any Interact",
            "Soft - Enemy",
            "Soft - Friend", -- 20
            "Soft - Interact",
            "I Am Tanking Elite+",
            "I Am Not Tanking Elite+",
            "I Have Aggro",
            "I Do Not Have Aggro"
        },
        shapeShiftChoicesEnum = {
            [0] = "None",
            "Bear Form",
            "Cat Form",
            "Travel Form",
            "Moonkin Form",
            "Tree of Life",
            "Voidform",
            "Shadowform",
            "Enrage",
            "Shadow Dance",
            "No Form",
            stance1,
            stance2,
            stance3,
            stance4,
            stance5,
            stance6,
            stance7,
        }
    }
    ConditionerAddOn.SharedConditionerFrame.DropDowns = {}
    ConditionerAddOn.SharedConditionerFrame.EditBoxes = {}
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes = {}

    -- aura target
    ConditionerAddOn.SharedConditionerFrame.DropDowns[5] = ConditionerAddOn:NewDropDown("Target Unit",
        "ConditionerAuraTargetDropDown", ConditionerAddOn.SharedConditionerFrame, 150, ConditionerAddOn.Enums
        .auraTargetChoicesEnum, "auraTargetEnum")
    ConditionerAddOn.SharedConditionerFrame.DropDowns[5]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame,
        "TOPRIGHT")

    ConditionerAddOn.SharedConditionerFrame.Background:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[5], "TOPLEFT", 4, 16)
    -- explain
    ConditionerAddOn.SharedConditionerFrame.Background.InfoButton = CreateFrame("Button", nil,
        ConditionerAddOn.SharedConditionerFrame.Background, "UIPanelInfoButton")
    ConditionerAddOn.SharedConditionerFrame.Background.InfoButton:SetPoint("CENTER",
        ConditionerAddOn.SharedConditionerFrame.Background, "TOPRIGHT")
    ConditionerAddOn.SharedConditionerFrame.Background.InfoButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, 0)
        GameTooltip:SetText("Conditions", 0, 0.75, 1)
        GameTooltip:AddLine(
            "Here you can set up additional conditions beyond only priority and cooldown for the tracking frames to monitor.\n\n|cff00ffff(AND)|r\nA spell or item will not be displayed unless it satisfies ALL of the criteria you specify here.\n\n|cff00ffff(OR)|r\nYou can insert the same spell or item as many times as you wish with different conditions to be satisfied, only a single instance will be displayed if its criteria is satisfied."
            ,
            1, 1, 1, true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.SharedConditionerFrame.Background.InfoButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    ConditionerAddOn.SharedConditionerFrame.Background.InfoButton:SetScript("OnClick", function(self)
        ConditionerAddOn.SharedConditionerFrame:Hide()
        if (ConditionerAddOn.CurrentPriorityButton) then
            -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
        end
    end)

    -- shapeshift form
    ConditionerAddOn.SharedConditionerFrame.DropDowns[6] = ConditionerAddOn:NewDropDown("Required Shapeshift Form",
        "ConditionerShapeShiftDropDown", ConditionerAddOn.SharedConditionerFrame, 150, ConditionerAddOn.Enums
        .shapeShiftChoicesEnum, "shapeShiftEnum")
    ConditionerAddOn.SharedConditionerFrame.DropDowns[6]:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[5], "BOTTOMLEFT", 0, -12)

    -- resource type 1
    ConditionerAddOn.SharedConditionerFrame.DropDowns[1] = ConditionerAddOn:NewDropDown("Resource Type",
        "ConditionerResourceDropDown", ConditionerAddOn.SharedConditionerFrame, 150,
        ConditionerAddOn.Enums.resourceEnum, "resourceTypeEnum")
    ConditionerAddOn.SharedConditionerFrame.DropDowns[1]:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[6], "BOTTOMLEFT", 0, -60)
    -- resource Conditional 1
    ConditionerAddOn.SharedConditionerFrame.DropDowns[2] = ConditionerAddOn:NewDropDown(nil,
        "ConditionerResourceDropDownOperator", ConditionerAddOn.SharedConditionerFrame, 75, ConditionerAddOn.Enums
        .conditionalOperatorEnum, "resourceConditionalEnum")
    ConditionerAddOn.SharedConditionerFrame.DropDowns[2]:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[1], "BOTTOMLEFT")
    -- resource Conditional 1 input box
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[1] = ConditionerAddOn:NewInputBox(
        ConditionerAddOn.SharedConditionerFrame, "resourceAmount", true)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[1]:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[2], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[1].title = "Resource Amount"
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[1].tooltip =
    "Enter an amount of resources you want Conditioner to track for you.\n\n|cffFFff00Right click to empty input box.|r"
    -- resource 1 checkbox
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[1] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame, "%", "resourceUsePercentageBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[1].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[1], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[1]:SetPoint("TOPRIGHT", ConditionerAddOn.SharedConditionerFrame
        .DropDowns[1], "BOTTOMRIGHT", -12, 0)
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[1].title = "Use Percentage"
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[1].tooltip =
    "Check this button if you would like this resource condition to be percentage based instead of a flat value."
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[1].linkedPercentBox =
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[1]
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[1].linkedEditBox =
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[1]
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[1]:SetPoint("RIGHT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[1], "LEFT")

    -- resource type 2
    ConditionerAddOn.SharedConditionerFrame.DropDowns[3] = ConditionerAddOn:NewDropDown("Resource Type",
        "ConditionerAltResourceDropDown", ConditionerAddOn.SharedConditionerFrame, 150, ConditionerAddOn.Enums
        .resourceEnum, "alternateResourceTypeEnum")
    ConditionerAddOn.SharedConditionerFrame.DropDowns[3]:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[1], "TOPRIGHT")
    -- resource Conditional 2
    ConditionerAddOn.SharedConditionerFrame.DropDowns[4] = ConditionerAddOn:NewDropDown(nil,
        "ConditionerAltResourceDropDownOperator", ConditionerAddOn.SharedConditionerFrame, 75, ConditionerAddOn.Enums
        .conditionalOperatorEnum, "alternateResourceConditionalEnum")
    ConditionerAddOn.SharedConditionerFrame.DropDowns[4]:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[3], "BOTTOMLEFT")
    -- resource Conditional 2 input box
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[2] = ConditionerAddOn:NewInputBox(
        ConditionerAddOn.SharedConditionerFrame, "alternateResourceAmount", true)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[2]:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[4], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[2].title = "Resource Amount"
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[2].tooltip =
    "Enter an amount of resources you want Conditioner to track for you.\n\n|cffFFff00Right click to empty input box.|r"
    -- resource 2 checkbox
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[2] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame, "%", "alternateResourceUsePercentageBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[2].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[2], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[2]:SetPoint("TOPRIGHT", ConditionerAddOn.SharedConditionerFrame
        .DropDowns[3], "BOTTOMRIGHT", -12, 0)
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[2].title = "Use Percentage"
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[2].tooltip =
    "Check this button if you would like this resource condition to be percentage based instead of a flat value."
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[2].linkedPercentBox =
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[2]
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[2].linkedEditBox =
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[2]
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[2]:SetPoint("RIGHT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[2], "LEFT")
    -- aura name
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3] = ConditionerAddOn:NewInputBox(
        ConditionerAddOn.SharedConditionerFrame, "activeAuraString")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:HookScript("OnEscapePressed", function()
        ConditionerAddOn.SharedConditionerFrame.ResultsBox:ClearResults()
        ConditionerAddOn.SharedConditionerFrame.ResultsBox:FixBackground()
    end)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:HookScript("OnHide", function()
        ConditionerAddOn.SharedConditionerFrame.ResultsBox:ClearResults()
        ConditionerAddOn.SharedConditionerFrame.ResultsBox:FixBackground()
    end)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:SetScript("OnEditFocusLost", function()
        closeResultsBox = true
    end)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[5], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:SetPoint("RIGHT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[3], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3].text =
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:CreateFontString(nil, "OVERLAY",
            "SystemFont_NamePlateCastBar")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3].text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3].text:SetPoint("BOTTOM",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[3], "TOP", 0, -6)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3].text:SetText("Active Aura Name")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3].text:SetJustifyH("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3].text:SetJustifyV("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3].text:SetTextColor(0, 1, 1, 1)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3].text:SetSize(
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[3].text:GetStringWidth(),
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:GetHeight())
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3].title = "Active Aura"
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3].tooltip =
    "Type in the name of a spell you want to track.\n\nConditioner will search if the spell is an active buff or debuff on your selected Target Unit. This field can interact with the Aura Seconds Remaining option. Spell ID numbers are supported.\n\n|cffFFff00Right click to empty input box.|r"

    -- aura search box
    ConditionerAddOn.SharedConditionerFrame.ResultsBox = CreateFrame("Frame", nil,
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[3])
    ConditionerAddOn.SharedConditionerFrame.ResultsBox:SetFrameStrata("HIGH")
    ConditionerAddOn.SharedConditionerFrame.ResultsBox:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[3], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.ResultsBox:SetPoint("TOPRIGHT",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[3], "BOTTOMRIGHT")
    ConditionerAddOn.SharedConditionerFrame.ResultsBox.Texture =
        ConditionerAddOn.SharedConditionerFrame.ResultsBox:CreateTexture()
    ConditionerAddOn.SharedConditionerFrame.ResultsBox.Texture:SetAllPoints(
        ConditionerAddOn.SharedConditionerFrame.ResultsBox)
    ConditionerAddOn.SharedConditionerFrame.ResultsBox.Texture:SetTexture(
        "Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
    ConditionerAddOn.SharedConditionerFrame.ResultsBox.Pool = {}
    ConditionerAddOn:AddBorder(ConditionerAddOn.SharedConditionerFrame.ResultsBox)
    function ConditionerAddOn.SharedConditionerFrame.ResultsBox:ClearResults()
        for k, v in ipairs(ConditionerAddOn.SharedConditionerFrame.ResultsBox.Pool) do
            v:Hide()
            v.isEmpty = true
            v:SetText("")
        end
    end

    function ConditionerAddOn.SharedConditionerFrame.ResultsBox:FixBackground()
        local PoolSize = 0
        for k, v in ipairs(ConditionerAddOn.SharedConditionerFrame.ResultsBox.Pool) do
            if (not v.isEmpty) then
                PoolSize = PoolSize + 1
            end
        end
        if (PoolSize > 0) then
            local standardHeight = ConditionerAddOn.SharedConditionerFrame.ResultsBox.Pool[PoolSize]:GetHeight()
            ConditionerAddOn.SharedConditionerFrame.ResultsBox:SetHeight(PoolSize * standardHeight)
            ConditionerAddOn.SharedConditionerFrame.ResultsBox:Show()
        else
            ConditionerAddOn.SharedConditionerFrame.ResultsBox:Hide()
        end
    end

    function ConditionerAddOn.SharedConditionerFrame.ResultsBox:GetResultButton(s)
        for k, v in ipairs(ConditionerAddOn.SharedConditionerFrame.ResultsBox.Pool) do
            if (v.isEmpty) then
                v:SetText(s)
                v.isEmpty = false
                v:Show()
                return v
            end
        end
        local EmptyPool = CreateFrame("Frame", nil, ConditionerAddOn.SharedConditionerFrame.ResultsBox)
        EmptyPool:SetFrameStrata("HIGH")
        local parentPool = #ConditionerAddOn.SharedConditionerFrame.ResultsBox.Pool
        EmptyPool:SetPoint("TOPLEFT",
            (parentPool > 0) and ConditionerAddOn.SharedConditionerFrame.ResultsBox.Pool[parentPool] or
            ConditionerAddOn.SharedConditionerFrame.ResultsBox, (parentPool > 0) and "BOTTOMLEFT" or "TOPLEFT")
        EmptyPool:SetPoint("RIGHT", ConditionerAddOn.SharedConditionerFrame.ResultsBox, "RIGHT")
        EmptyPool.isEmpty = false
        EmptyPool.Highlight = EmptyPool:CreateTexture()
        EmptyPool.Highlight:Hide()
        EmptyPool.Highlight:SetBlendMode("ADD")
        EmptyPool.Highlight:SetAllPoints(EmptyPool)
        EmptyPool.Highlight:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar-Blue")
        EmptyPool:SetScript("OnEnter", function(self)
            EmptyPool.Highlight:Show()
        end)
        EmptyPool:SetScript("OnLeave", function(self)
            EmptyPool.Highlight:Hide()
        end)
        function EmptyPool:SetText(s)
            if (not EmptyPool.text) then
                EmptyPool.text = EmptyPool:CreateFontString(nil, "OVERLAY", "SystemFont_NamePlateCastBar")
                EmptyPool.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
                EmptyPool.text:SetTextColor(1, 0.95, 0.15, 1)
                EmptyPool.text:SetPoint("LEFT", EmptyPool, "LEFT", 4, 0)
                EmptyPool.text:SetJustifyH("LEFT")
                EmptyPool.text:SetJustifyV("MIDDLE")
            end
            EmptyPool.text:SetText(s)
        end

        function EmptyPool:GetText()
            return EmptyPool.text:GetText()
        end

        EmptyPool:SetScript("OnMouseDown", function(self, button)
            ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:SetText(EmptyPool:GetText())
            ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:ClearFocus()
            ConditionerAddOn.SharedConditionerFrame.ResultsBox:ClearResults()
            ConditionerAddOn.SharedConditionerFrame.ResultsBox:FixBackground()

            local strippedString = ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:GetText():gsub("_", " ")
            ConditionerAddOn:SetCurrentCondition('activeAuraString', strippedString)
        end)
        EmptyPool:SetText(s)
        EmptyPool:SetHeight(20)
        table.insert(ConditionerAddOn.SharedConditionerFrame.ResultsBox.Pool, EmptyPool)
        return EmptyPool
    end

    -- search through cache
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:SetScript("OnTextChanged", function(self, userinput)
        -- try to populate results
        if (userinput) then
            local searchText = ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:GetText()
            ConditionerAddOn.SharedConditionerFrame.ResultsBox:ClearResults()
            if (#searchText > 0) then
                local lastNode, lastPrefix = ConditionerAddOn:SpellCacheTraverse(searchText, 1,
                    ConditionerAddOn.SpellCache)
                ConditionerAddOn:SpellCacheGetSuffixes(lastNode, lastPrefix,
                    ConditionerAddOn.SharedConditionerFrame.ResultsBox)
            end
        else
            if (#ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:GetText() == 0) then
                ConditionerAddOn.SharedConditionerFrame.ResultsBox:ClearResults()
            end
        end
        ConditionerAddOn.SharedConditionerFrame.ResultsBox:FixBackground()
    end)

    -- keybind
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4] = ConditionerAddOn:NewInputBox(
        ConditionerAddOn.SharedConditionerFrame, "keyBindingString")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4]:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[6], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4]:SetPoint("RIGHT",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[3], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4].text =
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[4]:CreateFontString(nil, "OVERLAY",
            "SystemFont_NamePlateCastBar")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4].text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4].text:SetPoint("BOTTOM",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[4], "TOP", 0, -6)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4].text:SetText("Displayed Key Binding")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4].text:SetJustifyH("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4].text:SetJustifyV("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4].text:SetTextColor(0, 1, 1, 1)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4].text:SetSize(
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[4].text:GetStringWidth(),
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[4]:GetHeight())
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4].title = "Displayed Key Binding"
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[4].tooltip =
    "This information will be displayed for its relative tracker icon.\n\n|cffFFff00Right click to empty input box.|r"

    -- stacks conditional
    ConditionerAddOn.SharedConditionerFrame.DropDowns[7] = ConditionerAddOn:NewDropDown(nil,
        "ConditionerStacksDropDown", ConditionerAddOn.SharedConditionerFrame, 75, ConditionerAddOn.Enums
        .conditionalOperatorEnum, "stackConditionalEnum")
    ConditionerAddOn.SharedConditionerFrame.DropDowns[7]:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[2], "BOTTOMLEFT", 0, -12)
    -- stacks amount
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5] = ConditionerAddOn:NewInputBox(
        ConditionerAddOn.SharedConditionerFrame, "stacksAmount", true)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5]:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[7], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5]:SetPoint("RIGHT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[1], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5].text =
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[5]:CreateFontString(nil, "OVERLAY",
            "SystemFont_NamePlateCastBar")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5].text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5].text:SetPoint("BOTTOM",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[7], "TOP", 0, -10)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5].text:SetPoint("CENTER",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[5], "CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5].text:SetText("Number of Aura Stacks")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5].text:SetJustifyH("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5].text:SetJustifyV("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5].text:SetTextColor(0, 1, 1, 1)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5].text:SetSize(150, ConditionerAddOn.SharedConditionerFrame
        .EditBoxes[5]:GetHeight())
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5].title = "Aura Stacks"
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[5].tooltip =
    "Aura stacks are the number of stacking buffs or debuffs a spell can accumulate on a target.\n\nMost spells can only stack once, unless otherwise stated in its tooltip.\n\n|cffFFff00Right click to empty input box.|r"

    -- charges conditional
    ConditionerAddOn.SharedConditionerFrame.DropDowns[8] = ConditionerAddOn:NewDropDown(nil,
        "ConditionerChargesDropDown", ConditionerAddOn.SharedConditionerFrame, 75, ConditionerAddOn.Enums
        .conditionalOperatorEnum, "chargesConditionalEnum")
    ConditionerAddOn.SharedConditionerFrame.DropDowns[8]:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[4], "BOTTOMLEFT", 0, -12)
    -- charges amount
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6] = ConditionerAddOn:NewInputBox(
        ConditionerAddOn.SharedConditionerFrame, "chargesAmount", true)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6]:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[8], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6]:SetPoint("RIGHT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[2], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6].text =
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[6]:CreateFontString(nil, "OVERLAY",
            "SystemFont_NamePlateCastBar")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6].text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6].text:SetPoint("BOTTOM",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[8], "TOP", 0, -10)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6].text:SetPoint("CENTER",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[3], "CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6].text:SetText("Number of Spell Charges")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6].text:SetJustifyH("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6].text:SetJustifyV("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6].text:SetTextColor(0, 1, 1, 1)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6].text:SetSize(150, ConditionerAddOn.SharedConditionerFrame
        .EditBoxes[6]:GetHeight())
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6].title = "Spell Charges"
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[6].tooltip =
    "A spell that has charges means that it can accumulate more than 1 cast over time.\n\nUsually you will see a number on your spell indicating how many charges it can store.\n\n|cffFFff00Right click to empty input box.|r"

    -- seconds remaining dropdown
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[3] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame, "Aura Seconds Remaining", "secondsRemainingBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[3].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[3], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[3]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .DropDowns[7]:GetName() .. "Middle", "BOTTOMLEFT", -10, 12)
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[3].title = "Use Aura Seconds Remaining"
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[3].tooltip =
    "Enable this option if you want to know when the Active Aura you specified has less than a certain amount of time remaining before it fades.\n\nThis will also inform you when the aura isn't applied to your target at all!"
    -- seconds remaining amount
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7] = ConditionerAddOn:NewInputBox(
        ConditionerAddOn.SharedConditionerFrame, "secondsRemainingAmount", true)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .DropDowns[8]:GetName() .. "Middle", "BOTTOMLEFT", 0, 8)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].text =
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[7]:CreateFontString(nil, "OVERLAY",
            "SystemFont_NamePlateCastBar")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].text:SetPoint("LEFT", ConditionerAddOn.SharedConditionerFrame
        .EditBoxes[7], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].text:SetText(" Seconds Remaining")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].text:SetJustifyH("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].text:SetJustifyV("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].text:SetTextColor(0, 1, 1, 1)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].text:SetSize(
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].text:GetStringWidth(),
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[7]:GetHeight())
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].title = "Seconds Remaining Amount"
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].tooltip =
    "This will inform you when the Active Aura has less than or equal to the amount of time you specify (or if it isn't active at all).\n\n|cffFFff00Right click to empty input box.|r"

    -- Has Enough Resources
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[4] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame, "Requirements Met", "canCast")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[4]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[3], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[4].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[4], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[4].title = "Requirements Met"
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[4].tooltip =
    "Enable this option if you want to know when you can cast the slotted spell.\n\nThis activates if the spell was throttled behind resources, another spell, or required state like Victory Rush/Raging Blow/Stealth/Execute/etc.\n\n|cffFFff00This is the most useful condition.|r"

    -- only when ready
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[5] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame, "Only When Off Cooldown", "onlyWhenReadyBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[5]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[4], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[5].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[5], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[5].title = "Only When Off Cooldown"
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[5].tooltip =
    "Enable this option if you want to know when this spell is fully finished cooling down and is ready to use."

    -- highlight only
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[6] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame, "Only When Highlighted", "highlightOnlyBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[6]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[5], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[6].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[6], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[6].title = "Only When Highlighted"
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[6].tooltip =
    "Enable this option if you want to know when this spell is highlighted, usually triggered from another spell."
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[6].demoButton = ConditionerAddOn.HighlightDemoButton

    -- only in range
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[13] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame, "Only Within Range", "onlyInRange")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[13]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[6], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[13].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[13], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[13].title = "Only Within Range"
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[13].tooltip =
    "Enable this option if you want to know when your Target Unit is within the range of your slotted spell."

    -- is interrupt
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[15] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame, "Interrupt Spell", "isInterruptBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[15]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[13], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[15].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[15], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[15].title = "Interrupt Spell"
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[15].tooltip =
    "Enable this option if this spell is meant to be used as an interrupt.\n\nThis condition is satisfied if your current target (regardless of the Target Unit choice) is casting a spell that can be interrupted and if your interrupt spell will be ready before it finishes!"

    -- dispel filter button
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton = CreateFrame("Button", nil,
        ConditionerAddOn.SharedConditionerFrame, "ConditionerButtonTemplate")
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].Left, "BOTTOMLEFT", -4, -6)
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton:SetPoint("RIGHT",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[7].text, "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton:SetHeight(32)
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton:SetText("Dispel Filter")
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor = CreateFrame("Frame", nil,
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton)
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:Hide()
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:SetSize(10, 10)
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:SetPoint("CENTER",
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton, "TOPRIGHT")

    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu = CreateFrame("Frame", nil,
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor)
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu:SetFrameStrata("BACKGROUND")
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Texture =
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu:CreateTexture()
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Texture:SetAllPoints(
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu)
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Texture:SetTexture(
        "Interface\\FrameGeneral\\UI-Background-Rock")
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor, "CENTER")
    ConditionerAddOn:AddBorder(ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu)

    -- debuff
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[7] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor, "Debuff", "debuffBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[7].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[7], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[7]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .DispelFilterButton.Anchor, "CENTER")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[7].filter = true

    -- buff
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[8] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor, "Buff", "buffBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[8].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[8], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[8]:SetPoint("LEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[7].text, "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[8].filter = true

    -- magic
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[9] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor, "Magic", "magicBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[9].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[9], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[9]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[8], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[9].filter = true

    -- curse
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[10] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor, "Curse", "curseBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[10].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[10], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[10]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[9], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[10].filter = true

    -- poison
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[11] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor, "Poison", "poisonBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[11].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[11], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[11]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[7], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[11].filter = true

    -- disease
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[12] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor, "Disease", "diseaseBool")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[12].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[12], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[12]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[11], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[12].filter = true

    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu:SetPoint("RIGHT",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[9].text, "RIGHT", 6, 0)
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu:SetPoint("BOTTOMLEFT",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[12], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Banner = CreateFrame("Frame", nil,
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu)
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Banner:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu, "TOPLEFT")
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Banner:SetPoint("TOPRIGHT",
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu, "TOPRIGHT")
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Banner:SetPoint("BOTTOMLEFT",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[7], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Banner.Texture =
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Banner:CreateTexture()
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Banner.Texture:SetAllPoints(
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Banner)
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Banner.Texture:SetTexture(
        "Interface\\FrameGeneral\\UI-Background-Marble")
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Menu.Banner.Texture:SetDrawLayer("BACKGROUND")

    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetText("Dispel Filter", 0, 0.75, 1)
        GameTooltip:AddLine(
            "Set any combination of buffs or debuffs with various dispel types to check on your Target Unit.", 1, 1, 1,
            true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    ConditionerAddOn.SharedConditionerFrame.DispelFilterButton:SetScript("OnClick", function(self)
        PlaySound(1115)
        if (ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:IsShown()) then
            ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:Hide()
        else
            ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:Show()
        end
        ConditionerCloseDropDownMenus()
        for k, v in pairs(ConditionerAddOn.SharedConditionerFrame.EditBoxes) do
            v:ClearFocus()
        end
    end)

    ConditionerAddOn.MainButton:SetScript("OnHide", function(self)
        ConditionerAddOn.SharedConditionerFrame:Hide()
        ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:Hide()
        if (ConditionerAddOn.CurrentPriorityButton) then
            -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
        end
        ConditionerAddOn.LoadoutFrame.InputName:Hide()
        ConditionerAddOn.LoadoutFrame.ImportExport:Hide()
    end)

    -- cooldown remaining
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining = CreateFrame("Button", nil,
        ConditionerAddOn.SharedConditionerFrame)
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:SetPoint("LEFT", ConditionerAddOn.SharedConditionerFrame
        .DispelFilterButton, "LEFT", 4, 0)
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:SetPoint("BOTTOM",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[6], "BOTTOM", 0, 6)
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:SetSize(50, 50)
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.Texture =
        ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:CreateTexture()
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.Texture:SetAllPoints(
        ConditionerAddOn.SharedConditionerFrame.CooldownRemaining)
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.Texture:SetTexture(
        "Interface\\FrameGeneral\\UI-Background-Marble")
    ConditionerAddOn:AddBorder(ConditionerAddOn.SharedConditionerFrame.CooldownRemaining)
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.HighlightTexture =
        ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:CreateTexture()
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.HighlightTexture:Hide()
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.HighlightTexture:SetAllPoints(
        ConditionerAddOn.SharedConditionerFrame.CooldownRemaining)
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.HighlightTexture:SetBlendMode("ADD")
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.HighlightTexture:SetTexture(
        "Interface\\Buttons\\CheckButtonHilight")

    function ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:ShowTooltip()
        GameTooltip:SetOwner(ConditionerAddOn.SharedConditionerFrame.CooldownRemaining, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetText("Cooldown Time Remaining", 0, 0.75, 1)
        GameTooltip:AddLine("Drag and place a spell or item here to track its remaining cooldown time in seconds.", 1,
            1, 1, true)
        if (ConditionerAddOn.CurrentPriorityButton) and
            (ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingID > 0) then
            local isItem = ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingIsItemID
            local cooldownName = (isItem) and
                GetItemInfo(ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingID) or
                GetSpellInfo(ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingID)
            GameTooltip:AddLine(string.format("\n%s : %s", cooldownName,
                ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingID), 0, 0.75, 1, true)
            GameTooltip:AddLine(string.format("Right Click - Stop Tracking %s's Cooldown", cooldownName), 1, 0.4, 1,
                true)
        end
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end

    function ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:UpdateIcon()
        if (ConditionerAddOn.CurrentPriorityButton) then
            local isItem = ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingIsItemID
            if (ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingID > 0) then
                local cooldownTexture = (isItem) and
                    GetItemIcon(
                        ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingID) or
                    GetSpellTexture(
                        ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingID)
                ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.Texture:SetTexture(cooldownTexture)
            else
                ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.Texture:SetTexture(
                    "Interface\\FrameGeneral\\UI-Background-Marble")
                ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingAmount = 0
                ConditionerAddOn.SharedConditionerFrame.EditBoxes[8]:Update()
            end
        end
    end

    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:SetScript("OnEnter", function(self)
        self:ShowTooltip()
        ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.HighlightTexture:Show()
    end)
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.HighlightTexture:Hide()
    end)

    -- cooldownRemainingEnum
    ConditionerAddOn.SharedConditionerFrame.DropDowns[9] = ConditionerAddOn:NewDropDown(nil, "ConditionerCDRDropDown",
        ConditionerAddOn.SharedConditionerFrame, 75, ConditionerAddOn.Enums.conditionalOperatorEnum,
        "cooldownRemainingEnum")
    ConditionerAddOn.SharedConditionerFrame.DropDowns[9]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CooldownRemaining, "BOTTOMLEFT", -20, 0)

    -- cooldown remaining amount
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8] = ConditionerAddOn:NewInputBox(
        ConditionerAddOn.SharedConditionerFrame, "cooldownRemainingAmount", true)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8]:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.DropDowns[9], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].text =
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[8]:CreateFontString(nil, "OVERLAY",
            "SystemFont_NamePlateCastBar")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].text:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.CooldownRemaining, "TOPRIGHT", 4, 0)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].text:SetPoint("BOTTOM",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[8], "TOP")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].text:SetText("Cooldown\nRemaining\nSeconds")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].text:SetJustifyH("LEFT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].text:SetJustifyV("TOP")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].text:SetTextColor(0, 1, 1, 1)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].text:SetSize(
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].text:GetStringWidth(),
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[8]:GetHeight())
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].title = "Cooldown Remaining Amount"
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[8].tooltip =
    "This will inform you when the selected spell or item's cooldown has the amount of time you specify.\n\n|cffFFff00Right click to empty input box.|r"
    ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:SetScript("OnClick", function(self, button, down)
        if (button == "RightButton") then
            ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingIsItemID = false
            ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingID = 0
            ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingAmount = 0
            ConditionerAddOn.SharedConditionerFrame.EditBoxes[8]:Update()
            ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.Texture:SetTexture(
                "Interface\\FrameGeneral\\UI-Background-Marble")
            ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:ShowTooltip()
            ConditionerAddOn.SharedConditionerFrame.EditBoxes[8]:ClearFocus()
            PlaySound(1202)
        elseif (button == "LeftButton") then
            local spellID, itemID = ConditionerAddOn:GetCursorInfo()
            if (spellID) then
                ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingIsItemID = (itemID > 0) and true or
                    false
                local newTexture = (itemID > 0) and GetItemIcon(itemID) or GetSpellTexture(spellID)
                ConditionerAddOn.CurrentPriorityButton.Conditions.cooldownRemainingID = ((itemID > 0) and itemID or
                    spellID) or 0
                ConditionerAddOn.SharedConditionerFrame.CooldownRemaining.Texture:SetTexture(newTexture)
                ClearCursor()
                ConditionerAddOn.SharedConditionerFrame.CooldownRemaining:ShowTooltip()
                PlaySound(1200)
            end
        end
    end)

    -- only while crowd controlled
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[14] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame, "Only While Controlled", "onlyDuringCC")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[14]:SetPoint("BOTTOM", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[15], "BOTTOM")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[14]:SetPoint("LEFT", ConditionerAddOn.SharedConditionerFrame
        .EditBoxes[7], "LEFT", -12, 0)
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[14].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[14], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[14].title = "Only While Controlled"
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[14].tooltip =
    "Enable this option if you want to know when you do not have full control of your character (Stunned/Feared/Mind Controlled/etc)."

    -- Stealth
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[16] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame, "Hide While Casting", "hideWhileCasting")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[16]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[14], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[16].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[16], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[16].title = "Hide While Casting"
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[16].tooltip =
    "Enable this option if you want to hide the spell if it is actively being cast."

    -- show in AoE rotation
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[17] = ConditionerAddOn:NewCheckBox(
        ConditionerAddOn.SharedConditionerFrame, "Area of Effect Only", "showInAoeRotation")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[17]:SetPoint("TOPLEFT", ConditionerAddOn.SharedConditionerFrame
        .CheckBoxes[15], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[17].text:SetPoint("LEFT",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[17], "RIGHT")
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[17].title = "Area of Effect Only"
    ConditionerAddOn.SharedConditionerFrame.CheckBoxes[17].tooltip =
    "Enable this option if this spell should appear in the AoE rotation instead of the primary rotation."

    -- myActiveAura
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9] = ConditionerAddOn:NewInputBox(
        ConditionerAddOn.SharedConditionerFrame, "myActiveAura")
    local activeAuraOffset = -20
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[4], "BOTTOMLEFT", 0, activeAuraOffset)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:SetPoint("TOPRIGHT",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[4], "BOTTOMRIGHT", 0, activeAuraOffset)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9].text =
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:CreateFontString(nil, "OVERLAY",
            "SystemFont_NamePlateCastBar")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9].text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9].text:SetPoint("BOTTOM",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[9], "TOP", 0, -6)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9].text:SetText("My Active Aura")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9].text:SetJustifyH("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9].text:SetJustifyV("CENTER")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9].text:SetTextColor(0, 1, 1, 1)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9].text:SetSize(
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[9].text:GetStringWidth(),
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:GetHeight())
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9].title = "My Active Aura"
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9].tooltip =
    "Check that a specific aura is active on YOURSELF. This is NOT related to the Aura Seconds Remaining option. Spell ID numbers are supported.\n\n|cffFFff00Right click to empty input box.|r"

    -- second aura search box
    ConditionerAddOn.SharedConditionerFrame.ResultsBox2 = CreateFrame("Frame", nil,
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[9])
    ConditionerAddOn.SharedConditionerFrame.ResultsBox2:SetFrameStrata("HIGH")
    ConditionerAddOn.SharedConditionerFrame.ResultsBox2:SetPoint("TOPLEFT",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[9], "BOTTOMLEFT")
    ConditionerAddOn.SharedConditionerFrame.ResultsBox2:SetPoint("TOPRIGHT",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[9], "BOTTOMRIGHT")
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:HookScript("OnEscapePressed", function()
        ConditionerAddOn.SharedConditionerFrame.ResultsBox2:ClearResults()
        ConditionerAddOn.SharedConditionerFrame.ResultsBox2:FixBackground()
    end)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:HookScript("OnHide", function()
        ConditionerAddOn.SharedConditionerFrame.ResultsBox2:ClearResults()
        ConditionerAddOn.SharedConditionerFrame.ResultsBox2:FixBackground()
    end)
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:SetScript("OnEditFocusLost", function()
        closeResultsBox2 = true
    end)
    ConditionerAddOn.SharedConditionerFrame.ResultsBox2.Texture =
        ConditionerAddOn.SharedConditionerFrame.ResultsBox2:CreateTexture()
    ConditionerAddOn.SharedConditionerFrame.ResultsBox2.Texture:SetAllPoints(
        ConditionerAddOn.SharedConditionerFrame.ResultsBox2)
    ConditionerAddOn.SharedConditionerFrame.ResultsBox2.Texture:SetTexture(
        "Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
    ConditionerAddOn.SharedConditionerFrame.ResultsBox2.Pool = {}
    ConditionerAddOn:AddBorder(ConditionerAddOn.SharedConditionerFrame.ResultsBox2)
    function ConditionerAddOn.SharedConditionerFrame.ResultsBox2:ClearResults()
        for k, v in ipairs(ConditionerAddOn.SharedConditionerFrame.ResultsBox2.Pool) do
            v:Hide()
            v.isEmpty = true
            v:SetText("")
        end
    end

    function ConditionerAddOn.SharedConditionerFrame.ResultsBox2:FixBackground()
        local PoolSize = 0
        for k, v in ipairs(ConditionerAddOn.SharedConditionerFrame.ResultsBox2.Pool) do
            if (not v.isEmpty) then
                PoolSize = PoolSize + 1
            end
        end
        if (PoolSize > 0) then
            local standardHeight = ConditionerAddOn.SharedConditionerFrame.ResultsBox2.Pool[PoolSize]:GetHeight()
            ConditionerAddOn.SharedConditionerFrame.ResultsBox2:SetHeight(PoolSize * standardHeight)
            ConditionerAddOn.SharedConditionerFrame.ResultsBox2:Show()
        else
            ConditionerAddOn.SharedConditionerFrame.ResultsBox2:Hide()
        end
    end

    function ConditionerAddOn.SharedConditionerFrame.ResultsBox2:GetResultButton(s)
        for k, v in ipairs(ConditionerAddOn.SharedConditionerFrame.ResultsBox2.Pool) do
            if (v.isEmpty) then
                v:SetText(s)
                v.isEmpty = false
                v:Show()
                return v
            end
        end
        local EmptyPool = CreateFrame("Frame", nil, ConditionerAddOn.SharedConditionerFrame.ResultsBox2)
        EmptyPool:SetFrameStrata("HIGH")
        local parentPool = #ConditionerAddOn.SharedConditionerFrame.ResultsBox2.Pool
        EmptyPool:SetPoint("TOPLEFT",
            (parentPool > 0) and ConditionerAddOn.SharedConditionerFrame.ResultsBox2.Pool[parentPool] or
            ConditionerAddOn.SharedConditionerFrame.ResultsBox2, (parentPool > 0) and "BOTTOMLEFT" or "TOPLEFT")
        EmptyPool:SetPoint("RIGHT", ConditionerAddOn.SharedConditionerFrame.ResultsBox2, "RIGHT")
        EmptyPool.isEmpty = false
        EmptyPool.Highlight = EmptyPool:CreateTexture()
        EmptyPool.Highlight:Hide()
        EmptyPool.Highlight:SetBlendMode("ADD")
        EmptyPool.Highlight:SetAllPoints(EmptyPool)
        EmptyPool.Highlight:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar-Blue")
        EmptyPool:SetScript("OnEnter", function(self)
            EmptyPool.Highlight:Show()
        end)
        EmptyPool:SetScript("OnLeave", function(self)
            EmptyPool.Highlight:Hide()
        end)
        function EmptyPool:SetText(s)
            if (not EmptyPool.text) then
                EmptyPool.text = EmptyPool:CreateFontString(nil, "OVERLAY", "SystemFont_NamePlateCastBar")
                EmptyPool.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
                EmptyPool.text:SetTextColor(1, 0.95, 0.15, 1)
                EmptyPool.text:SetPoint("LEFT", EmptyPool, "LEFT", 4, 0)
                EmptyPool.text:SetJustifyH("LEFT")
                EmptyPool.text:SetJustifyV("MIDDLE")
            end
            EmptyPool.text:SetText(s)
        end

        function EmptyPool:GetText()
            return EmptyPool.text:GetText()
        end

        EmptyPool:SetScript("OnMouseDown", function(self, button)
            ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:SetText(EmptyPool:GetText())
            ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:ClearFocus()
            ConditionerAddOn.SharedConditionerFrame.ResultsBox2:ClearResults()
            ConditionerAddOn.SharedConditionerFrame.ResultsBox2:FixBackground()

            local strippedString = ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:GetText():gsub("_", " ")
            ConditionerAddOn:SetCurrentCondition('myActiveAura', strippedString)
        end)
        EmptyPool:SetText(s)
        EmptyPool:SetHeight(20)
        table.insert(ConditionerAddOn.SharedConditionerFrame.ResultsBox2.Pool, EmptyPool)
        return EmptyPool
    end

    -- search through cache
    ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:SetScript("OnTextChanged", function(self, userinput)
        -- try to populate results
        if (userinput) then
            local searchText = ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:GetText()
            ConditionerAddOn.SharedConditionerFrame.ResultsBox2:ClearResults()
            if (#searchText > 0) then
                local lastNode, lastPrefix = ConditionerAddOn:SpellCacheTraverse(searchText, 1,
                    ConditionerAddOn.SpellCache)
                ConditionerAddOn:SpellCacheGetSuffixes(lastNode, lastPrefix,
                    ConditionerAddOn.SharedConditionerFrame.ResultsBox2)
            end
        else
            if (#ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:GetText() == 0) then
                ConditionerAddOn.SharedConditionerFrame.ResultsBox2:ClearResults()
            end
        end
        ConditionerAddOn.SharedConditionerFrame.ResultsBox2:FixBackground()
    end)

    -- =============================================================================================================================--
    -----------------------------------------------SHARED CONDITIONS WINDOW BACKGROUND-----------------------------------------------
    -- =============================================================================================================================--
    ConditionerAddOn.SharedConditionerFrame.Background:SetPoint("BOTTOM",
        ConditionerAddOn.SharedConditionerFrame.CheckBoxes[16], "BOTTOM", 0, -6)
    ConditionerAddOn.SharedConditionerFrame.Background:SetPoint("RIGHT",
        ConditionerAddOn.SharedConditionerFrame.EditBoxes[3], "RIGHT", 12, 0)
    ConditionerAddOn:AddBorder(ConditionerAddOn.SharedConditionerFrame.Background)
    ConditionerAddOn.SharedConditionerFrame.Background.Title =
        ConditionerAddOn.SharedConditionerFrame.Background:CreateFontString(nil, "OVERLAY",
            "SystemFont_OutlineThick_Huge2")
    ConditionerAddOn.SharedConditionerFrame.Background.Title:SetTextColor(0, 1, 1, 1)
    ConditionerAddOn.SharedConditionerFrame.Background.Title:SetPoint("BOTTOM",
        ConditionerAddOn.SharedConditionerFrame
        .Background, "TOP")
    ConditionerAddOn.SharedConditionerFrame.Background.Title:SetText("DEFAULT")
    ConditionerAddOn.SharedConditionerFrame.Background.Title.Texture =
        ConditionerAddOn.SharedConditionerFrame.Background:CreateTexture()
    ConditionerAddOn.SharedConditionerFrame.Background.Title.Texture:SetPoint("BOTTOM",
        ConditionerAddOn.SharedConditionerFrame.Background, "TOP")
    ConditionerAddOn.SharedConditionerFrame.Background.Title.Texture:SetBlendMode("ADD")
    ConditionerAddOn.SharedConditionerFrame.Background.Title.Texture:SetTexture(
        "Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar-Blue")
    ConditionerAddOn.SharedConditionerFrame.Background.Title.Texture:SetHeight(
        ConditionerAddOn.SharedConditionerFrame.Background.Title:GetStringHeight())

    -- =============================================================================================================================--
    -----------------------------------------------SHARED CONDITIONS WINDOW BACKGROUND-----------------------------------------------
    -- =============================================================================================================================--
    -- Loadout Window
    ConditionerAddOn.LoadoutFrame = CreateFrame("Frame", nil, SpellBookFrame)
    ConditionerAddOn.LoadoutFrame.DragTexture = ConditionerAddOn.LoadoutFrame:CreateTexture()
    ConditionerAddOn.LoadoutFrame.DragTexture:SetAllPoints(ConditionerAddOn.LoadoutFrame)
    ConditionerAddOn.LoadoutFrame.DragTexture:SetDrawLayer("BACKGROUND")
    SetPortraitTexture(ConditionerAddOn.LoadoutFrame.DragTexture, "player")
    ConditionerAddOn.LoadoutFrame.MaskTexture = ConditionerAddOn.LoadoutFrame:CreateTexture()
    ConditionerAddOn.LoadoutFrame.MaskTexture:SetPoint("CENTER", ConditionerAddOn.LoadoutFrame.DragTexture, "CENTER",
        52, -18)
    ConditionerAddOn.LoadoutFrame.MaskTexture:SetTexture("Interface\\AddOns\\Conditioner\\Assets\\silverDragonFlipped")
    ConditionerAddOn.LoadoutFrame.MaskTexture:SetDrawLayer("BACKGROUND")
    ConditionerAddOn.LoadoutFrame.InfoButton = CreateFrame("Frame", nil, ConditionerAddOn.LoadoutFrame)
    ConditionerAddOn.LoadoutFrame.InfoButton:SetPoint("CENTER", ConditionerAddOn.LoadoutFrame, "BOTTOMLEFT", 7, 10)
    ConditionerAddOn.LoadoutFrame.InfoButton:SetFrameStrata("HIGH")
    ConditionerAddOn.LoadoutFrame.InfoButton:SetSize(22, 22)
    ConditionerAddOn.LoadoutFrame.InfoButton.Texture = ConditionerAddOn.LoadoutFrame.InfoButton:CreateTexture()
    ConditionerAddOn.LoadoutFrame.InfoButton.Texture:SetAllPoints(ConditionerAddOn.LoadoutFrame.InfoButton)
    ConditionerAddOn.LoadoutFrame.InfoButton.Texture:SetTexture("Interface\\FriendsFrame\\InformationIcon")
    ConditionerAddOn.LoadoutFrame.InfoButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
        GameTooltip:SetText("Options and Loadouts", 0, 0.75, 1)
        GameTooltip:AddLine(
            "Click and drag the portrait to move the options window around.\n\nHere you will find the ability to save/import/export loadouts along with additional options on how you want your tracking frames displayed.\n\n|cffFFff00You MUST save a rotation in the loadout menu in order for it to persist.|r"
            ,
            1, 1, 1, true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.LoadoutFrame.InfoButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    ConditionerAddOn.LoadoutFrame:SetFrameStrata("HIGH")
    ConditionerAddOn.LoadoutFrame:SetSize(58, 58)
    ConditionerAddOn.LoadoutFrame:SetPoint("CENTER", UIParent, "CENTER", 150, UIParent:GetHeight() / 3)
    ConditionerAddOn.LoadoutFrame:SetMovable(true)
    ConditionerAddOn.LoadoutFrame:EnableMouse(true)
    ConditionerAddOn.LoadoutFrame:SetClampedToScreen(true)
    ConditionerAddOn.LoadoutFrame:RegisterForDrag("LeftButton")
    ConditionerAddOn.LoadoutFrame:SetScript("OnDragStart", function(self, button)
        self:StartMoving()
        for k, v in pairs(ConditionerAddOn.SharedConditionerFrame.EditBoxes) do
            v:ClearFocus()
        end
    end)
    ConditionerAddOn.LoadoutFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    ConditionerAddOn.LoadoutFrame:SetScript("OnShow", function(self)
        SetPortraitTexture(ConditionerAddOn.LoadoutFrame.DragTexture, "player")
    end)

    -- input box for loadout name and the imported loadout string
    ConditionerAddOn.LoadoutFrame.InputName = CreateFrame("EditBox", nil, ConditionerAddOn.LoadoutFrame,
        "InputBoxTemplate")
    ConditionerAddOn.LoadoutFrame.InputName:Hide()
    ConditionerAddOn.LoadoutFrame.InputName:SetSize(150, 32)
    ConditionerAddOn.LoadoutFrame.InputName:SetPoint("CENTER", UIParent, "CENTER")
    ConditionerAddOn.LoadoutFrame.InputName:SetAutoFocus(false)
    ConditionerAddOn.LoadoutFrame.InputName.Title = ConditionerAddOn.LoadoutFrame.InputName:CreateFontString(nil,
        "OVERLAY", "SystemFont_Huge1_Outline")
    ConditionerAddOn.LoadoutFrame.InputName.Title:SetTextColor(0, 1, 1)
    ConditionerAddOn.LoadoutFrame.InputName.Title:SetText("New Loadout")
    ConditionerAddOn.LoadoutFrame.InputName.Title:SetPoint("BOTTOM", ConditionerAddOn.LoadoutFrame.InputName, "TOP")
    ConditionerAddOn.LoadoutFrame.InputName:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    ConditionerAddOn.LoadoutFrame.InputName:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    ConditionerAddOn.LoadoutFrame.InputName:SetScript("OnMouseDown", function(self, button)
        local nextFreeLoadoutSlot = ConditionerAddOn:GetNextLoadoutSlot()
        local defaultCheck = (ConditionerAddOn.LoadoutFrame.DropDown.Choices) and
            (string.format("New Loadout %s", nextFreeLoadoutSlot)) or ""
        if (button == "RightButton") or (self:GetText() == defaultCheck) then
            self:SetText("")
        end
    end)
    ConditionerAddOn.LoadoutFrame.InputName:SetScript("OnShow", function(self)
        if (ConditionerAddOn.LoadoutFrame.DropDown.Choices) then
            local nextFreeLoadoutSlot = ConditionerAddOn:GetNextLoadoutSlot()
            local newIndex = nextFreeLoadoutSlot
            self:SetText(string.format("New Loadout %s", newIndex))
        end
    end)
    ConditionerAddOn.LoadoutFrame.InputName:SetScript("OnEnter", function(self, ...)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetText("Loadout Name", 0, 0.75, 1)
        GameTooltip:AddLine("Enter a name for your loadout.", 1, 1, 1, true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.LoadoutFrame.InputName:SetScript("OnLeave", function(self, ...)
        GameTooltip:Hide()
    end)
    ConditionerAddOn.LoadoutFrame.InputName.SubmitButton = CreateFrame("Button", nil,
        ConditionerAddOn.LoadoutFrame.InputName, "ConditionerButtonTemplate")
    ConditionerAddOn.LoadoutFrame.InputName.SubmitButton:SetText("Save")
    ConditionerAddOn.LoadoutFrame.InputName.SubmitButton:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.InputName,
        "BOTTOMLEFT")
    ConditionerAddOn.LoadoutFrame.InputName.SubmitButton:SetPoint("RIGHT", ConditionerAddOn.LoadoutFrame.InputName,
        "BOTTOM")
    ConditionerAddOn.LoadoutFrame.InputName.SubmitButton:SetHeight(32)
    ConditionerAddOn.LoadoutFrame.InputName.SubmitButton:SetScript("OnClick", function(self)
        PlaySound(1115)
        local currentSpecID = ConditionerGetSpecializationInfo(ConditionerGetSpecialization())
        local loadoutName = ConditionerAddOn.LoadoutFrame.InputName:GetText()
        local loadoutString = ConditionerAddOn:CreateLoadoutString()
        if (loadoutString) then
            if (loadoutName == "") then
                UIErrorsFrame:Clear()
                UIErrorsFrame:AddMessage("Please enter a name for your loadout.", 0, 0.75, 1, 1)
            else
                local package = {
                    name = loadoutName,
                    value = loadoutString,
                    spec = currentSpecID
                }
                local nextFreeLoadoutSlot = ConditionerAddOn:GetNextLoadoutSlot()
                ConditionerAddOn.LoadoutFrame.DropDown.Choices[nextFreeLoadoutSlot] = package
                -- table.insert(ConditionerAddOn.LoadoutFrame.DropDown.Choices, package)
                ConditionerAddOn.LoadoutFrame.InputName:Hide()

                ConditionerAddOn.LoadoutFrame.DropDown:SetValue(nextFreeLoadoutSlot)
            end
        else
            UIErrorsFrame:Clear()
            UIErrorsFrame:AddMessage("You have no rotation set up to save!", 0, 0.75, 1, 1)
        end
        ConditionerCloseDropDownMenus()
    end)

    ConditionerAddOn.LoadoutFrame.InputName.CancelButton = CreateFrame("Button", nil,
        ConditionerAddOn.LoadoutFrame.InputName, "ConditionerButtonTemplate")
    ConditionerAddOn.LoadoutFrame.InputName.CancelButton:SetText("Cancel")
    ConditionerAddOn.LoadoutFrame.InputName.CancelButton:SetPoint("TOPRIGHT", ConditionerAddOn.LoadoutFrame.InputName,
        "BOTTOMRIGHT")
    ConditionerAddOn.LoadoutFrame.InputName.CancelButton:SetPoint("LEFT", ConditionerAddOn.LoadoutFrame.InputName,
        "BOTTOM")
    ConditionerAddOn.LoadoutFrame.InputName.CancelButton:SetHeight(32)
    ConditionerAddOn.LoadoutFrame.InputName.CancelButton:SetScript("OnClick", function(self)
        PlaySound(1115)
        ConditionerAddOn.LoadoutFrame.InputName:Hide()
        ConditionerCloseDropDownMenus()
    end)

    -- IMPORT/EXPORT INPUTBOX
    ConditionerAddOn.LoadoutFrame.ImportExport = CreateFrame("EditBox", nil, ConditionerAddOn.LoadoutFrame,
        "InputBoxTemplate")
    ConditionerAddOn.LoadoutFrame.ImportExport.Reason = 0
    ConditionerAddOn.LoadoutFrame.ImportExport:Hide()
    ConditionerAddOn.LoadoutFrame.ImportExport:SetFrameStrata("HIGH")
    ConditionerAddOn.LoadoutFrame.ImportExport:SetAutoFocus(false)
    ConditionerAddOn.LoadoutFrame.ImportExport:SetSize(150, 32)
    ConditionerAddOn.LoadoutFrame.ImportExport.Background = CreateFrame("Frame", nil,
        ConditionerAddOn.LoadoutFrame.ImportExport)
    ConditionerAddOn.LoadoutFrame.ImportExport.Background:SetFrameStrata("BACKGROUND")
    ConditionerAddOn.LoadoutFrame.ImportExport.Background:SetPoint("TOPLEFT",
        ConditionerAddOn.LoadoutFrame.ImportExport, "TOPLEFT", -16, 0)
    ConditionerAddOn.LoadoutFrame.ImportExport.Background:SetPoint("RIGHT", ConditionerAddOn.LoadoutFrame.ImportExport,
        "RIGHT", 10, 0)
    ConditionerAddOn.LoadoutFrame.ImportExport.Texture =
        ConditionerAddOn.LoadoutFrame.ImportExport.Background:CreateTexture()
    ConditionerAddOn.LoadoutFrame.ImportExport.Texture:SetDrawLayer("BACKGROUND")
    ConditionerAddOn.LoadoutFrame.ImportExport.Texture:SetAllPoints(
        ConditionerAddOn.LoadoutFrame.ImportExport.Background)
    ConditionerAddOn.LoadoutFrame.ImportExport.Texture:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")
    ConditionerAddOn:AddBorder(ConditionerAddOn.LoadoutFrame.ImportExport.Background)
    -- IMPORT/EXPORT CANCEL BUTTON
    ConditionerAddOn.LoadoutFrame.ImportExport.CancelButton = CreateFrame("Button", nil,
        ConditionerAddOn.LoadoutFrame.ImportExport, "ConditionerButtonTemplate")
    ConditionerAddOn.LoadoutFrame.ImportExport.CancelButton:SetText("Close")
    ConditionerAddOn.LoadoutFrame.ImportExport.CancelButton:SetPoint("TOPRIGHT",
        ConditionerAddOn.LoadoutFrame.ImportExport, "BOTTOMRIGHT")
    ConditionerAddOn.LoadoutFrame.ImportExport.CancelButton:SetPoint("TOPLEFT",
        ConditionerAddOn.LoadoutFrame.ImportExport, "BOTTOM")
    ConditionerAddOn.LoadoutFrame.ImportExport.CancelButton:SetHeight(32)
    ConditionerAddOn.LoadoutFrame.ImportExport.CancelButton:SetScript("OnClick", function(self)
        PlaySound(1115)
        ConditionerAddOn.LoadoutFrame.ImportExport:Hide()
        ConditionerAddOn.LoadoutFrame.ImportExport:ClearFocus()
        ConditionerCloseDropDownMenus()
    end)
    -- IMPORT/EXPORT APPLY/OKAY BUTTON
    ConditionerAddOn.LoadoutFrame.ImportExport.AcceptButton = CreateFrame("Button", nil,
        ConditionerAddOn.LoadoutFrame.ImportExport, "ConditionerButtonTemplate")
    ConditionerAddOn.LoadoutFrame.ImportExport.AcceptButton:SetText("Apply")
    ConditionerAddOn.LoadoutFrame.ImportExport.AcceptButton:SetPoint("TOPLEFT",
        ConditionerAddOn.LoadoutFrame.ImportExport, "BOTTOMLEFT")
    ConditionerAddOn.LoadoutFrame.ImportExport.AcceptButton:SetPoint("TOPRIGHT",
        ConditionerAddOn.LoadoutFrame.ImportExport, "BOTTOM")
    ConditionerAddOn.LoadoutFrame.ImportExport.AcceptButton:SetHeight(32)
    ConditionerAddOn.LoadoutFrame.ImportExport.AcceptButton:SetScript("OnClick", function(self)
        PlaySound(1115)
        if (ConditionerAddOn.LoadoutFrame.ImportExport.Reason == 1) then
            -- clear current one
            ConditionerAddOn:ClearCurrentLoadout()
            -- apply the current text as a loadout
            local loadoutString = ConditionerAddOn.LoadoutFrame.ImportExport:GetText()
            ConditionerAddOn:ApplyLoadout(false, loadoutString)
            ConditionerAddOn.LoadoutFrame.ImportExport:Hide()
        elseif (ConditionerAddOn.LoadoutFrame.ImportExport.Reason == 2) then
            -- make it highlight the text
            ConditionerAddOn.LoadoutFrame.ImportExport:SetFocus()
            ConditionerAddOn.LoadoutFrame.ImportExport:HighlightText()
        end
        ConditionerAddOn:StoreCurrentLoadout()
        ConditionerCloseDropDownMenus()
    end)

    ConditionerAddOn.LoadoutFrame.ImportExport:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetText("Import Loadout", 0, 0.75, 1)
        GameTooltip:AddLine(
            "Paste a loadout string into the text box and click Apply to load the rotation you received, it won't overwrite or be saved unless you Create New Loadout with it applied."
            ,
            1, 1, 1, true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.LoadoutFrame.ImportExport:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    ConditionerAddOn.LoadoutFrame.ImportExport.Background:SetPoint("BOTTOM",
        ConditionerAddOn.LoadoutFrame.ImportExport
        .AcceptButton, "BOTTOM", 0, 0)
    ConditionerAddOn.LoadoutFrame.ImportExport:SetPoint("CENTER", UIParent, "CENTER")

    ConditionerAddOn.LoadoutFrame.ImportExport.Message = ConditionerAddOn.LoadoutFrame.ImportExport:CreateFontString(
        nil, "OVERLAY", "SystemFont_Huge1_Outline")
    ConditionerAddOn.LoadoutFrame.ImportExport.Message:SetTextColor(0, 1, 1)
    ConditionerAddOn.LoadoutFrame.ImportExport.Message:SetPoint("BOTTOM", ConditionerAddOn.LoadoutFrame.ImportExport,
        "TOP")
    ConditionerAddOn.LoadoutFrame.ImportExport:SetScript("OnMouseDown", function(self, button)
        ConditionerAddOn.LoadoutFrame.ImportExport:HighlightText()
    end)

    -- container
    ConditionerAddOn.LoadoutFrame.InputName.Background = CreateFrame("Frame", nil,
        ConditionerAddOn.LoadoutFrame.InputName)
    ConditionerAddOn.LoadoutFrame.InputName.Background:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.InputName,
        "TOPLEFT", -16, 0)
    ConditionerAddOn.LoadoutFrame.InputName.Background:SetPoint("BOTTOM",
        ConditionerAddOn.LoadoutFrame.InputName.CancelButton, "BOTTOM")
    ConditionerAddOn.LoadoutFrame.InputName.Background:SetPoint("RIGHT", ConditionerAddOn.LoadoutFrame.InputName,
        "RIGHT", 10, 0)
    ConditionerAddOn.LoadoutFrame.InputName.Background:SetFrameStrata("MEDIUM")
    ConditionerAddOn.LoadoutFrame.InputName.Background.Texture =
        ConditionerAddOn.LoadoutFrame.InputName.Background:CreateTexture()
    ConditionerAddOn.LoadoutFrame.InputName.Background.Texture:SetAllPoints(
        ConditionerAddOn.LoadoutFrame.InputName.Background)
    ConditionerAddOn.LoadoutFrame.InputName.Background.Texture:SetTexture(
        "Interface\\FrameGeneral\\UI-Background-Marble")
    ConditionerAddOn:AddBorder(ConditionerAddOn.LoadoutFrame.InputName.Background)
    -----------------------------------------

    ConditionerAddOn.LoadoutFrame.SpecializationInfo = CreateFrame("Frame", nil, ConditionerAddOn.LoadoutFrame)
    ConditionerAddOn.LoadoutFrame.SpecializationInfo:SetSize(50, 50)
    ConditionerAddOn.LoadoutFrame.SpecializationInfo.Texture =
        ConditionerAddOn.LoadoutFrame.SpecializationInfo:CreateTexture()
    ConditionerAddOn.LoadoutFrame.SpecializationInfo.Texture:SetAllPoints(ConditionerAddOn.LoadoutFrame
        .SpecializationInfo)
    ConditionerAddOn.LoadoutFrame.SpecializationInfo.SpecName =
        ConditionerAddOn.LoadoutFrame.SpecializationInfo:CreateFontString(nil, "OVERLAY", "SystemFont_Huge1_Outline")
    ConditionerAddOn.LoadoutFrame.SpecializationInfo.SpecName:SetTextColor(0, 1, 1)
    ConditionerAddOn.LoadoutFrame.SpecializationInfo:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame, "TOPRIGHT", 6, 0)

    -- loadout dropdown
    ConditionerAddOn.LoadoutFrame.DropDown = CreateFrame("Frame", "ConditionerLoadOutDropDown",
        ConditionerAddOn.LoadoutFrame, "ConditionerUIDropDownMenuTemplate")
    ConditionerAddOn.LoadoutFrame.SpecializationInfo.SpecName:SetPoint("BOTTOM", ConditionerAddOn.LoadoutFrame.DropDown,
        "TOP")
    ConditionerAddOn.LoadoutFrame.DropDown:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.SpecializationInfo, "RIGHT")
    ConditionerAddOn.LoadoutFrame.DropDown.Choices = ConditionerAddOn_SavedVariables_Loadouts
    ConditionerAddOn.LoadoutFrame.DropDown.text = ConditionerAddOn.LoadoutFrame.DropDown:CreateFontString(nil,
        "OVERLAY", "SystemFont_NamePlateCastBar")
    ConditionerAddOn.LoadoutFrame.DropDown.text:SetPoint("BOTTOM", ConditionerAddOn.LoadoutFrame.DropDown, "TOP", 0, -12)
    ConditionerAddOn.LoadoutFrame.DropDown.text:SetText(title)
    ConditionerAddOn.LoadoutFrame.DropDown.text:SetJustifyH("CENTER")
    ConditionerAddOn.LoadoutFrame.DropDown.text:SetJustifyV("CENTER")
    ConditionerAddOn.LoadoutFrame.DropDown.text:SetTextColor(0, 1, 1, 1)
    ConditionerAddOn.LoadoutFrame.DropDown.text:SetSize(ConditionerAddOn.LoadoutFrame.DropDown.text:GetStringWidth(),
        ConditionerAddOn.LoadoutFrame.DropDown:GetHeight())
    CONDITIONERDROPDOWNMENU_SetWidth(ConditionerAddOn.LoadoutFrame.DropDown, 150)
    ConditionerAddOn.LoadoutFrame.DropDown:SetScript("OnShow", function(self)
        local currentSpecID, specName, specDesc, specIcon, specBackground, specRole, specPrimaryStat =
            ConditionerGetSpecializationInfo(ConditionerGetSpecialization())
        local _, classFileName = UnitClass("player")
        local color = (RAID_CLASS_COLORS) and RAID_CLASS_COLORS[classFileName] or {
            r = 0,
            g = 1,
            b = 1
        }
        ConditionerAddOn.LoadoutFrame.SpecializationInfo.Texture:SetTexture(specIcon)
        ConditionerAddOn.LoadoutFrame.SpecializationInfo.SpecName:SetTextColor(color.r, color.g, color.b)
        ConditionerAddOn.LoadoutFrame.SpecializationInfo.SpecName:SetText(specName)
        ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice =
            ConditionerAddOn_SavedVariables.CurrentLoadouts[currentSpecID] or 0
        -- is the currentChoice still valid? we might have deleted it on a diff char or even overwritten the slot with a diff spec's loadout
        if (not ConditionerAddOn.LoadoutFrame.DropDown.Choices[ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice]) or
            (
                ConditionerAddOn.LoadoutFrame.DropDown.Choices[ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice].spec ~=
                currentSpecID) then
            ConditionerAddOn_SavedVariables.CurrentLoadouts[currentSpecID] = 0
            ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice = 0
        end
        local textValue = ConditionerAddOn.LoadoutFrame.DropDown.Choices[ConditionerAddOn.LoadoutFrame.DropDown
        .CurrentChoice].name
        if (ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice == -1) then
            ConditionerAddOn.LoadoutFrame.SaveLoadout:LockHighlight()
            textValue = string.format("|cffFFff00%s|r", textValue)
            ConditionerAddOn:WarningCreateNewLoadout(ConditionerAddOn.LoadoutFrame.SaveLoadout)
        elseif (ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice == 0) then
            ConditionerAddOn.LoadoutFrame.SaveLoadout:LockHighlight()
            textValue = string.format("|cffd742f4%s|r", textValue)
            ConditionerAddOn:WarningCreateNewLoadout(ConditionerAddOn.LoadoutFrame.SaveLoadout)
        else
            ConditionerAddOn.LoadoutFrame.SaveLoadout:UnlockHighlight()
            ConditionerAddOn:WarningCreateNewLoadout(nil, true)
        end
        CONDITIONERDROPDOWNMENU_SetText(ConditionerAddOn.LoadoutFrame.DropDown, textValue)
        CONDITIONERDROPDOWNMENU_Initialize(ConditionerAddOn.LoadoutFrame.DropDown, function(self, level, menuList)
            for k, v in pairs(ConditionerAddOn.SharedConditionerFrame.EditBoxes) do
                v:ClearFocus()
            end
            if (ConditionerAddOn.SharedConditionerFrame.DispelFilterButton) and
                (ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor) then
                ConditionerAddOn.SharedConditionerFrame.DispelFilterButton.Anchor:Hide()
            end
            local info = CONDITIONERDROPDOWNMENU_CreateInfo()
            info.text = ConditionerAddOn.LoadoutFrame.DropDown.Choices[0].name
            info.func = self.SetValue
            info.arg1 = 0
            info.checked = (0 == ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice)
            CONDITIONERDROPDOWNMENU_AddButton(info)
            -- basic rotation
            if (ConditionerAddOn.LoadoutFrame.DropDown.Choices[-1]) then
                info.text = ConditionerAddOn.LoadoutFrame.DropDown.Choices[-1].name
                info.func = self.SetValue
                info.arg1 = -1
                info.checked = (-1 == ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice)
                CONDITIONERDROPDOWNMENU_AddButton(info)
            end
            for k, v in pairs(ConditionerAddOn.LoadoutFrame.DropDown.Choices) do
                if (v) then
                    if (currentSpecID == v.spec) then
                        info.text = v.name
                        info.func = self.SetValue
                        info.arg1 = k
                        info.checked = (k == ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice)
                        CONDITIONERDROPDOWNMENU_AddButton(info)
                    end
                end
            end
        end)
        ConditionerAddOn:StoreCurrentLoadout()
    end)

    function ConditionerAddOn.LoadoutFrame.DropDown:SetValue(newValue)
        ConditionerAddOn.SharedConditionerFrame:Hide()
        if (ConditionerAddOn.CurrentPriorityButton) then
            -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
        end
        ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice = newValue
        local textValue = ConditionerAddOn.LoadoutFrame.DropDown.Choices[ConditionerAddOn.LoadoutFrame.DropDown
        .CurrentChoice].name
        if (newValue == -1) then
            ConditionerAddOn.LoadoutFrame.SaveLoadout:LockHighlight()
            textValue = string.format("|cffFFff00%s|r", textValue)
            ConditionerAddOn:WarningCreateNewLoadout(ConditionerAddOn.LoadoutFrame.SaveLoadout)
        elseif (newValue == 0) then
            ConditionerAddOn.LoadoutFrame.SaveLoadout:LockHighlight()
            textValue = string.format("|cffd742f4%s|r", textValue)
            ConditionerAddOn:WarningCreateNewLoadout(ConditionerAddOn.LoadoutFrame.SaveLoadout)
        else
            ConditionerAddOn.LoadoutFrame.SaveLoadout:UnlockHighlight()
            ConditionerAddOn:WarningCreateNewLoadout(nil, true)
        end
        CONDITIONERDROPDOWNMENU_SetText(ConditionerAddOn.LoadoutFrame.DropDown, textValue)
        ConditionerCloseDropDownMenus()
        ConditionerAddOn:ClearCurrentLoadout()
        local savedPackage =
            ConditionerAddOn:GetLoadoutPackageByID(ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice)
        if (savedPackage) then
            ConditionerAddOn:ApplyLoadout(savedPackage)
        end
        ConditionerAddOn:StoreCurrentLoadout()
        ConditionerAddOn.LoadoutFrame.InputName:Hide()
        ConditionerAddOn.LoadoutFrame.ImportExport:Hide()
    end

    function ConditionerAddOn.LoadoutFrame.DropDown:DeleteLoadout()
        if (ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice > 0) then
            ConditionerAddOn.LoadoutFrame.DropDown.Choices[ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice] = false
            CONDITIONERDROPDOWNMENU_SetText(ConditionerAddOn.LoadoutFrame.DropDown, string.format("|cffd742f4%s|r",
                ConditionerAddOn.LoadoutFrame.DropDown.Choices[0].name))
            ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice = 0
            ConditionerAddOn.LoadoutFrame.SaveLoadout:LockHighlight()
            ConditionerAddOn:WarningCreateNewLoadout(ConditionerAddOn.LoadoutFrame.SaveLoadout)
            ConditionerAddOn:StoreCurrentLoadout()
            if (ConditionerAddOn.CurrentPriorityButton) then
                -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
            end
            ConditionerAddOn.SharedConditionerFrame:Hide()
        end
    end

    -- CREATE LOADOUT
    ConditionerAddOn.LoadoutFrame.SaveLoadout = CreateFrame("Button", nil, ConditionerAddOn.LoadoutFrame,
        "ConditionerButtonTemplate")
    ConditionerAddOn.LoadoutFrame.SaveLoadout:SetText("Create New Loadout")
    ConditionerAddOn.LoadoutFrame.SaveLoadout:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.SpecializationInfo,
        "BOTTOMLEFT", 0, -6)
    ConditionerAddOn.LoadoutFrame.SaveLoadout:SetSize(150, 32)
    ConditionerAddOn.LoadoutFrame.SaveLoadout:SetScript("OnClick", function(self, button, down)
        PlaySound(1115)
        ConditionerAddOn.LoadoutFrame.InputName:Show()
        ConditionerAddOn.LoadoutFrame.ImportExport:Hide()
        if (ConditionerAddOn.CurrentPriorityButton) then
            ConditionerAddOn.SharedConditionerFrame:Hide()
            -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
        end
    end)
    ConditionerAddOn.LoadoutFrame.SaveLoadout:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, 0)
        GameTooltip:SetText("Create New Loadout", 0, 0.75, 1)
        GameTooltip:AddLine(
            "|cffd742f4None|r/|cffFFff00Basic Rotation|r can NOT be overwritten.\n\nYou MUST create a new loadout if you wish to save your modifications!"
            ,
            1, 1, 1, true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.LoadoutFrame.SaveLoadout:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    -- OVERWRITE CURRENT LOADOUT
    ConditionerAddOn.LoadoutFrame.OverWrite = CreateFrame("Button", nil, ConditionerAddOn.LoadoutFrame,
        "ConditionerButtonTemplate")
    ConditionerAddOn.LoadoutFrame.OverWrite:SetText("Save")
    ConditionerAddOn.LoadoutFrame.OverWrite:SetPoint("LEFT", ConditionerAddOn.LoadoutFrame.DropDown, "RIGHT", 0, 2)
    ConditionerAddOn.LoadoutFrame.OverWrite:SetSize(80, 32)
    ConditionerAddOn.LoadoutFrame.OverWrite:SetScript("OnClick", function(self, button, down)
        PlaySound(1115)
        if (ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice > 0) then
            local overwriteString = ConditionerAddOn:CreateLoadoutString()
            ConditionerAddOn.LoadoutFrame.DropDown.Choices[ConditionerAddOn.LoadoutFrame.DropDown.CurrentChoice].value =
                overwriteString
            ConditionerAddOn.LoadoutFrame.OverWrite:Disable()
            ConditionerAddOn.LoadoutFrame.OverWrite:UnlockHighlight()
            ConditionerAddOn.LoadoutFrame.OverWrite:SetText("Saved")
            ConditionerAddOn:UnsavedChanges(nil, true)
        end
    end)

    -- TRASH
    ConditionerAddOn.LoadoutFrame.TrashCan = CreateFrame("Button", nil, ConditionerAddOn.LoadoutFrame,
        "ConditionerButtonTemplate")
    ConditionerAddOn.LoadoutFrame.TrashCan:SetText("Delete")
    ConditionerAddOn.LoadoutFrame.TrashCan:SetPoint("LEFT", ConditionerAddOn.LoadoutFrame.OverWrite, "RIGHT")
    ConditionerAddOn.LoadoutFrame.TrashCan:SetSize(80, 32)
    ConditionerAddOn.LoadoutFrame.TrashCan:SetScript("OnClick", function(self, button, down)
        PlaySound(1202)
        ConditionerAddOn.LoadoutFrame.DropDown:DeleteLoadout()
        ConditionerCloseDropDownMenus()
    end)

    -- import loadout string
    ConditionerAddOn.LoadoutFrame.ImportLoadout = CreateFrame("Button", nil, ConditionerAddOn.LoadoutFrame,
        "ConditionerButtonTemplate")
    ConditionerAddOn.LoadoutFrame.ImportLoadout:SetText("Import Loadout")
    ConditionerAddOn.LoadoutFrame.ImportLoadout:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.SaveLoadout,
        "BOTTOMLEFT")
    ConditionerAddOn.LoadoutFrame.ImportLoadout:SetSize(ConditionerAddOn.LoadoutFrame.SaveLoadout:GetWidth(),
        ConditionerAddOn.LoadoutFrame.SaveLoadout:GetHeight())
    ConditionerAddOn.LoadoutFrame.ImportLoadout:SetScript("OnClick", function(self, button, down)
        PlaySound(1115)
        ConditionerAddOn.LoadoutFrame.ImportExport:SetText("")
        ConditionerAddOn.LoadoutFrame.ImportExport.Message:SetText("Import Loadout")
        ConditionerAddOn.LoadoutFrame.InputName:Hide()
        ConditionerAddOn.LoadoutFrame.ImportExport.Reason = 1
        ConditionerAddOn.LoadoutFrame.ImportExport:EnableMouse(true)
        ConditionerAddOn.LoadoutFrame.ImportExport.AcceptButton:SetText("Apply")
        ConditionerAddOn.LoadoutFrame.ImportExport:Show()
        ConditionerAddOn.LoadoutFrame.ImportExport:SetFocus()
        if (ConditionerAddOn.CurrentPriorityButton) then
            ConditionerAddOn.SharedConditionerFrame:Hide()
            -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
        end
    end)

    -- export loadout
    ConditionerAddOn.LoadoutFrame.ExportLoadout = CreateFrame("Button", nil, ConditionerAddOn.LoadoutFrame,
        "ConditionerButtonTemplate")
    ConditionerAddOn.LoadoutFrame.ExportLoadout:SetText("Export Loadout")
    ConditionerAddOn.LoadoutFrame.ExportLoadout:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.ImportLoadout,
        "BOTTOMLEFT")
    ConditionerAddOn.LoadoutFrame.ExportLoadout:SetSize(ConditionerAddOn.LoadoutFrame.SaveLoadout:GetWidth(),
        ConditionerAddOn.LoadoutFrame.SaveLoadout:GetHeight())
    ConditionerAddOn.LoadoutFrame.ExportLoadout:SetScript("OnClick", function(self, button, down)
        PlaySound(1115)
        local currentLoadout = ConditionerAddOn:CreateLoadoutString(true)
        if (currentLoadout) then
            ConditionerAddOn.LoadoutFrame.ImportExport:SetText(currentLoadout)
            ConditionerAddOn.LoadoutFrame.ImportExport.Message:SetText("Export Loadout")
            ConditionerAddOn.LoadoutFrame.InputName:Hide()
            ConditionerAddOn.LoadoutFrame.ImportExport.Reason = 2
            ConditionerAddOn.LoadoutFrame.ImportExport:EnableMouse(false)
            ConditionerAddOn.LoadoutFrame.ImportExport.AcceptButton:SetText("Select")
            ConditionerAddOn.LoadoutFrame.ImportExport:Show()
            ConditionerAddOn.LoadoutFrame.ImportExport:ClearFocus()
            if (ConditionerAddOn.CurrentPriorityButton) then
                ConditionerAddOn.SharedConditionerFrame:Hide()
                -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
            end
        end
    end)

    ConditionerAddOn.LoadoutFrame.BackgroundFrame = CreateFrame("Frame", nil, ConditionerAddOn.LoadoutFrame)
    ConditionerAddOn.LoadoutFrame.BackgroundFrame:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame, "TOPRIGHT", 0, 6)
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Texture =
        ConditionerAddOn.LoadoutFrame.BackgroundFrame:CreateTexture()
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Texture:SetAllPoints(ConditionerAddOn.LoadoutFrame.BackgroundFrame)
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Texture:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Texture:SetDrawLayer("BACKGROUND")
    ConditionerAddOn:AddBorder(ConditionerAddOn.LoadoutFrame.BackgroundFrame)
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Signature =
        ConditionerAddOn.LoadoutFrame.BackgroundFrame:CreateFontString(nil, "OVERLAY", "SystemFont_NamePlateCastBar")
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Signature:SetTextColor(0.2, 0.2, 0.2, 0.2)
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Signature:SetPoint("TOPRIGHT",
        ConditionerAddOn.LoadoutFrame.BackgroundFrame, "TOPRIGHT", 0, -4)
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Signature:SetText("Developed By: Tony Allain")
    ConditionerAddOn.LoadoutFrame.BackgroundFrame:SetPoint("RIGHT", ConditionerAddOn.LoadoutFrame.TrashCan, "RIGHT")
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Title =
        ConditionerAddOn.LoadoutFrame.BackgroundFrame:CreateFontString(nil, "OVERLAY", "SystemFont_OutlineThick_WTF")
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Title:SetTextColor(0, 1, 1)
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Title:SetText("Conditioner")
    ConditionerAddOn.LoadoutFrame.BackgroundFrame.Title:SetPoint("BOTTOMLEFT",
        ConditionerAddOn.LoadoutFrame.BackgroundFrame, "TOPLEFT")

    -- Icon At Mouse Icon Tracker
    ConditionerAddOn.MouseIconTracker = CreateFrame("Frame", nil, UIParent)
    ConditionerAddOn.MouseIconTracker.Pool = {}
    function ConditionerAddOn:HideTrackerPool(pool)
        for i, v in ipairs(pool) do
            v.available = true
            v:Hide()
        end
    end

    function ConditionerAddOn:GetTrackerFromPool(pool)
        -- is one available?
        for i, v in ipairs(pool) do
            if (v.available) then
                return v
            end
        end

        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetFrameLevel(UIParent:GetFrameLevel() + 5) -- some arbitrary amount higher than parent
        frame.available = true
        frame:Hide()
        ConditionerAddOn:AddBorder(frame)

        -- mouse icon texture
        frame.Texture = frame:CreateTexture()
        frame.Texture:SetAllPoints(frame)
        -- frame.Texture:SetDrawLayer("BACKGROUND")
        frame.Texture:SetTexCoord(cropAmount, 1 - cropAmount, cropAmount, 1 - cropAmount)

        -- mouse icon cooldown
        frame.Cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
        frame.Cooldown:SetAllPoints(frame)

        -- keybind
        frame.KeybindFrame = CreateFrame("Frame", nil, frame)
        frame.KeybindFrame:SetAllPoints(frame)
        frame.KeybindFrame:SetFrameStrata(frame:GetFrameStrata())
        frame.Keybind = frame.KeybindFrame:CreateFontString(nil, "OVERLAY", "SystemFont_NamePlateCastBar")
        -- frame.Keybind:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 6.25)
        frame.Keybind:SetJustifyH("LEFT")
        frame.Keybind:SetJustifyV("BOTTOM")
        frame.Keybind:SetTextColor(0, 1, 1, 1)

        -- add to pool
        table.insert(pool, frame)

        return frame
    end

    -- mouse tracker position to cursor
    ConditionerAddOn:InitSavedVars()
    ConditionerAddOn.MouseIconTracker:SetScript("OnUpdate", function(self, elapsed)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetScale()
        local size = ConditionerAddOn_SavedVariables.Options.TrackedFrameSize or 100
        local width = size * scale * (ConditionerAddOn_SavedVariables.Options.MouseOverIconScale / 100)
        ConditionerAddOn.MouseIconTracker:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
            (x / scale - width) + ConditionerAddOn_SavedVariables.Options.MouseOverOffsetX,
            y / scale + ConditionerAddOn_SavedVariables.Options.MouseOverOffsetY)
        ConditionerAddOn.MouseIconTracker:SetSize(width, width)
    end)

    -- AoE rotation tracker
    ConditionerAddOn.AoeRotation = CreateFrame("Frame", nil, SpellBookFrame)
    ConditionerAddOn.AoeRotation.Pool = {}
    ConditionerAddOn.AoeRotation.x =
        ConditionerAddOn_SavedVariables.Options.AoeRotationAnchor.x or UIParent:GetWidth() / 2
    ConditionerAddOn.AoeRotation.y =
        ConditionerAddOn_SavedVariables.Options.AoeRotationAnchor.y or UIParent:GetHeight() / 2
    ConditionerAddOn.AoeRotation:SetFrameStrata("HIGH")
    ConditionerAddOn.AoeRotation:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ConditionerAddOn.AoeRotation.x,
        ConditionerAddOn.AoeRotation.y)
    ConditionerAddOn.AoeRotation:SetSize(64, 64)
    ConditionerAddOn.AoeRotation.Anchor = CreateFrame("Frame")
    local rotationAnchorSize = UIParent:GetScale() * 0.5 *
        (ConditionerAddOn_SavedVariables.Options.TrackedFrameSize or 100)
    ConditionerAddOn.AoeRotation.Anchor:SetSize(rotationAnchorSize, rotationAnchorSize)
    ConditionerAddOn.AoeRotation.Anchor:SetPoint("CENTER", ConditionerAddOn.AoeRotation, "CENTER")
    ConditionerAddOn.AoeRotation.Texture = ConditionerAddOn.AoeRotation:CreateTexture()
    ConditionerAddOn.AoeRotation.Texture:SetAllPoints(ConditionerAddOn.AoeRotation)
    ConditionerAddOn.AoeRotation.Texture:SetDrawLayer("BACKGROUND")
    SetPortraitToTexture(ConditionerAddOn.AoeRotation.Texture, "Interface\\DialogFrame\\UI-DialogBox-Background")
    ConditionerAddOn.AoeRotation.Text = ConditionerAddOn.AoeRotation:CreateFontString(nil, "OVERLAY",
        "SystemFont_NamePlateCastBar")
    ConditionerAddOn.AoeRotation.Text:SetPoint("CENTER", ConditionerAddOn.AoeRotation, "CENTER")
    ConditionerAddOn.AoeRotation.Text:SetTextColor(0, 1, 1, 1)
    ConditionerAddOn.AoeRotation.Text:SetText("AoE\nTracked\nFrame\nAnchor")
    ConditionerAddOn.AoeRotation:EnableMouse(true)
    ConditionerAddOn.AoeRotation:RegisterForDrag("LeftButton")
    ConditionerAddOn.AoeRotation:SetMovable(true)
    ConditionerAddOn.AoeRotation:SetClampedToScreen(true)
    ConditionerAddOn.AoeRotation:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    ConditionerAddOn.AoeRotation:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local left, bottom, width, height = self:GetRect()
        ConditionerAddOn_SavedVariables.Options.AoeRotationAnchor.x = (left + width / 2)
        ConditionerAddOn_SavedVariables.Options.AoeRotationAnchor.y = (bottom + height / 2)
    end)
    -- handle size
    ConditionerAddOn.AoeRotation:SetScript("OnUpdate", function(self, elapsed)
        local scale = UIParent:GetScale() * 0.5
        local size = ConditionerAddOn_SavedVariables.Options.TrackedFrameSize or 100
        local width = size * scale
        ConditionerAddOn.AoeRotation.Anchor:SetSize(width, width)
    end)

    -- ===================================================================================================================--
    --------------------------------------------------------OPTIONS--------------------------------------------------------
    -- ===================================================================================================================--
    -- STYLE CONTAINER
    ConditionerAddOn.LoadoutFrame.OptionsContainer = CreateFrame("Frame", nil, ConditionerAddOn.LoadoutFrame)
    ConditionerAddOn:AddBorder(ConditionerAddOn.LoadoutFrame.OptionsContainer)

    -- NUM TRACKER FRAMES
    ConditionerAddOn.LoadoutFrame.NumTrackedFrames = ConditionerAddOn:NewSlider(ConditionerAddOn.LoadoutFrame,
        "ConditionerNumTrackedFrames", "1", "10", 1, 10, "Max Tracked Frames", 5, "NumTrackedFrames", true)
    ConditionerAddOn.LoadoutFrame.NumTrackedFrames:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.ExportLoadout,
        "BOTTOMLEFT", 5, -20)
    -- AOE NUM TRACKER FRAMES
    ConditionerAddOn.LoadoutFrame.AoeNumTrackedFrames = ConditionerAddOn:NewSlider(ConditionerAddOn.LoadoutFrame,
        "ConditionerAoeNumTrackedFrames", "1", "10", 1, 10, "AoE Frames", 5, "AoeNumTrackedFrames", true)
    ConditionerAddOn.LoadoutFrame.AoeNumTrackedFrames:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.NumTrackedFrames
        ,
        "BOTTOMLEFT", 0,
        -25)
    -- MOUSEOVER NUM TRACKER FRAMES
    ConditionerAddOn.LoadoutFrame.MouseoverNumTrackedFrames = ConditionerAddOn:NewSlider(ConditionerAddOn.LoadoutFrame,
        "ConditionerMouseoverNumTrackedFrames", "1", "10", 1, 10, "Mouseover Frames", 5,
        "MouseoverNumTrackedFrames", true)
    ConditionerAddOn.LoadoutFrame.MouseoverNumTrackedFrames:SetPoint("TOPLEFT",
        ConditionerAddOn.LoadoutFrame.AoeNumTrackedFrames,
        "BOTTOMLEFT", 0,
        -25)
    -- TAPER SIZE
    ConditionerAddOn.LoadoutFrame.TaperSize = ConditionerAddOn:NewSlider(ConditionerAddOn.LoadoutFrame,
        "ConditionerTaperSize", "25%", "100%", 25, 100, "Taper Size", 80, "TaperSize")
    ConditionerAddOn.LoadoutFrame.TaperSize:SetPoint("TOP", ConditionerAddOn.LoadoutFrame.MouseoverNumTrackedFrames,
        "BOTTOM", 0,
        -25)
    -- OPACITY
    ConditionerAddOn.LoadoutFrame.Opacity = ConditionerAddOn:NewSlider(ConditionerAddOn.LoadoutFrame,
        "ConditionerOpacity", "25%", "100%", 25, 100, "Opacity", 100, "Opacity")
    ConditionerAddOn.LoadoutFrame.Opacity:SetPoint("TOP", ConditionerAddOn.LoadoutFrame.TaperSize, "BOTTOM", 0, -25)
    -- GCD CLIPPING
    ConditionerAddOn.LoadoutFrame.ClipGCD = ConditionerAddOn:NewSlider(ConditionerAddOn.LoadoutFrame,
        "ConditionerClipping", "0%", "100%", 0, 100, "GCD Factor", 0, "ClipGCD")
    ConditionerAddOn.LoadoutFrame.ClipGCD:SetPoint("TOP", ConditionerAddOn.LoadoutFrame.Opacity, "BOTTOM", 0, -25)
    -- MOUSEOVER OFFSET X
    ConditionerAddOn.LoadoutFrame.MouseOverOffsetX = ConditionerAddOn:NewSlider(ConditionerAddOn.LoadoutFrame,
        "ConditionerMouseOverOffsetX", "-50", "+50", -50, 50, "Mouseover Offset X", 0, "MouseOverOffsetX", true)
    ConditionerAddOn.LoadoutFrame.MouseOverOffsetX:SetPoint("TOP", ConditionerAddOn.LoadoutFrame.ClipGCD, "BOTTOM", 0,
        -25)
    -- MOUSEOVER OFFSET Y
    ConditionerAddOn.LoadoutFrame.MouseOverOffsetY = ConditionerAddOn:NewSlider(ConditionerAddOn.LoadoutFrame,
        "ConditionerMouseOverOffsetY", "-50", "+50", -50, 50, "Mouseover Offset Y", 0, "MouseOverOffsetY", true)
    ConditionerAddOn.LoadoutFrame.MouseOverOffsetY:SetPoint("TOP", ConditionerAddOn.LoadoutFrame.MouseOverOffsetX,
        "BOTTOM", 0,
        -25)
    -- MOUSEOVER SCALE
    ConditionerAddOn.LoadoutFrame.MouseOverIconScale = ConditionerAddOn:NewSlider(ConditionerAddOn.LoadoutFrame,
        "ConditionerMouseOverIconScale", "10%", "200%", 10, 200, "Mouseover Scale", 50, "MouseOverIconScale", true)
    ConditionerAddOn.LoadoutFrame.MouseOverIconScale:SetPoint("TOP", ConditionerAddOn.LoadoutFrame.MouseOverOffsetY,
        "BOTTOM", 0,
        -25)

    local lastFrameToStretchTo = ConditionerAddOn.LoadoutFrame.MouseOverIconScale

    -- ONLY IN COMBAT
    ConditionerAddOn.LoadoutFrame.AlwaysShow = CreateFrame("CheckButton", nil, ConditionerAddOn.LoadoutFrame,
        "UICheckButtonTemplate")
    ConditionerAddOn.LoadoutFrame.AlwaysShow.text = ConditionerAddOn.LoadoutFrame.AlwaysShow:CreateFontString(nil,
        "OVERLAY")
    ConditionerAddOn.LoadoutFrame.AlwaysShow.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.LoadoutFrame.AlwaysShow.text:SetText("Only Display In Combat")
    ConditionerAddOn.LoadoutFrame.AlwaysShow.text:SetJustifyH("LEFT")
    ConditionerAddOn.LoadoutFrame.AlwaysShow.text:SetTextColor(0.1, 0.9, 1, 1)
    ConditionerAddOn.LoadoutFrame.AlwaysShow.text:SetPoint("LEFT", ConditionerAddOn.LoadoutFrame.AlwaysShow, "RIGHT")
    ConditionerAddOn.LoadoutFrame.AlwaysShow:SetPoint("LEFT", ConditionerAddOn.LoadoutFrame.NumTrackedFrames, "RIGHT",
        16, 0)
    ConditionerAddOn.LoadoutFrame.AlwaysShow:SetPoint("TOP", ConditionerAddOn.LoadoutFrame.SaveLoadout, "TOP")
    ConditionerAddOn.LoadoutFrame.AlwaysShow:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetText("Only Display In Combat", 0, 0.75, 1)
        GameTooltip:AddLine(
            "Check this option if you only want to have your rotation displayed in combat, otherwise it will be displayed at all times."
            ,
            1, 1, 1, true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.LoadoutFrame.AlwaysShow:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    ConditionerAddOn.LoadoutFrame.AlwaysShow:SetScript("OnClick", function(self)
        PlaySound(1115)
        ConditionerAddOn_SavedVariables.Options.OnlyDisplayInCombat = self:GetChecked()
    end)
    ConditionerAddOn.LoadoutFrame.AlwaysShow:SetScript("OnShow", function(self)
        self:SetChecked(ConditionerAddOn_SavedVariables.Options.OnlyDisplayInCombat)
    end)

    -- SWING TIMERS
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers = CreateFrame("CheckButton", nil, ConditionerAddOn.LoadoutFrame,
        "UICheckButtonTemplate")
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers.text = ConditionerAddOn.LoadoutFrame.ShowSwingTimers:CreateFontString(
        nil, "OVERLAY")
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers.text:SetText("Show My Swing Timers")
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers.text:SetJustifyH("LEFT")
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers.text:SetTextColor(0.1, 0.9, 1, 1)
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers.text:SetPoint("LEFT", ConditionerAddOn.LoadoutFrame.ShowSwingTimers,
        "RIGHT")
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.AlwaysShow,
        "BOTTOMLEFT", 0, 0)
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetText("Show Swing Timers", 0, 0.75, 1)
        GameTooltip:AddLine("Check this option to display your Main-Hand and Off-Hand swing timers.", 1, 1, 1, true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers:SetScript("OnClick", function(self)
        PlaySound(1115)
        ConditionerAddOn_SavedVariables.Options.ShowSwingTimers = self:GetChecked()
    end)
    ConditionerAddOn.LoadoutFrame.ShowSwingTimers:SetScript("OnShow", function(self)
        self:SetChecked(ConditionerAddOn_SavedVariables.Options.ShowSwingTimers)
    end)

    -- HIDE RANGED SWING TIMER
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer = CreateFrame("CheckButton", nil, ConditionerAddOn.LoadoutFrame,
        "UICheckButtonTemplate")
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer.text = ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer
        :CreateFontString(
            nil, "OVERLAY")
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer.text:SetText("Hide My Ranged Shot Timer")
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer.text:SetJustifyH("LEFT")
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer.text:SetTextColor(0.1, 0.9, 1, 1)
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer.text:SetPoint("LEFT",
        ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer,
        "RIGHT")
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.ShowSwingTimers,
        "BOTTOMLEFT", 0, 0)
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetText("Hide Ranged Shot Timer", 0, 0.75, 1)
        GameTooltip:AddLine(
            "Check this option to hide your Ranged shot swing timer if you have Show Swing Timers enabled.", 1, 1, 1,
            true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer:SetScript("OnClick", function(self)
        PlaySound(1115)
        ConditionerAddOn_SavedVariables.Options.HideRangedSwingTimer = self:GetChecked()
    end)
    ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer:SetScript("OnShow", function(self)
        self:SetChecked(ConditionerAddOn_SavedVariables.Options.HideRangedSwingTimer)
    end)

    -- show cast bar
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar = CreateFrame("CheckButton", nil, ConditionerAddOn.LoadoutFrame,
        "UICheckButtonTemplate")
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar.text =
        ConditionerAddOn.LoadoutFrame.ShowTargetCastBar:CreateFontString(nil, "OVERLAY")
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar.text:SetText("Show Target Cast Bar")
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar.text:SetJustifyH("LEFT")
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar.text:SetTextColor(0.1, 0.9, 1, 1)
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar.text:SetPoint("LEFT",
        ConditionerAddOn.LoadoutFrame.ShowTargetCastBar, "RIGHT")
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar:SetPoint("TOPLEFT",
        ConditionerAddOn.LoadoutFrame.HideRangedSwingTimer,
        "BOTTOMLEFT", 0, 0)
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetText("Show Target Cast Bar", 0, 0.75, 1)
        GameTooltip:AddLine(
            "Check this option to display your current target's cast bar above your primary tracking frame, colored yellow if it can be interrupted or grey if it cannot be interrupted."
            ,
            1, 1, 1, true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar:SetScript("OnClick", function(self)
        PlaySound(1115)
        ConditionerAddOn_SavedVariables.Options.ShowTargetCastBar = self:GetChecked()
    end)
    ConditionerAddOn.LoadoutFrame.ShowTargetCastBar:SetScript("OnShow", function(self)
        self:SetChecked(ConditionerAddOn_SavedVariables.Options.ShowTargetCastBar)
    end)

    -- show mouseover abilities at cursor
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor = CreateFrame("CheckButton", nil, ConditionerAddOn.LoadoutFrame,
        "UICheckButtonTemplate")
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor.text =
        ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor:CreateFontString(nil, "OVERLAY")
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor.text:SetText("Show Mouseover Rotation")
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor.text:SetJustifyH("LEFT")
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor.text:SetTextColor(0.1, 0.9, 1, 1)
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor.text:SetPoint("LEFT", ConditionerAddOn.LoadoutFrame
        .ShowMouseoverAtCursor, "RIGHT")
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor:SetPoint("TOPLEFT",
        ConditionerAddOn.LoadoutFrame.ShowTargetCastBar, "BOTTOMLEFT", 0, 0)
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetText("Show Mouseover Rotation", 0, 0.75, 1)
        GameTooltip:AddLine(
            "Check this option to display your mouseover abilities at your cursor instead of the rotation frames.", 1,
            1, 1, true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor:SetScript("OnClick", function(self)
        PlaySound(1115)
        ConditionerAddOn_SavedVariables.Options.ShowMouseoverAtCursor = self:GetChecked()
    end)
    ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor:SetScript("OnShow", function(self)
        self:SetChecked(ConditionerAddOn_SavedVariables.Options.ShowMouseoverAtCursor)
    end)

    -- show AoE rotation
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation = CreateFrame("CheckButton", nil, ConditionerAddOn.LoadoutFrame,
        "UICheckButtonTemplate")
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation.text = ConditionerAddOn.LoadoutFrame.ShowAoeRotation:CreateFontString(
        nil, "OVERLAY")
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE, THICK")
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation.text:SetText("Show AoE Rotation")
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation.text:SetJustifyH("LEFT")
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation.text:SetTextColor(0.1, 0.9, 1, 1)
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation.text:SetPoint("LEFT", ConditionerAddOn.LoadoutFrame.ShowAoeRotation,
        "RIGHT")
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation:SetPoint("TOPLEFT",
        ConditionerAddOn.LoadoutFrame.ShowMouseoverAtCursor, "BOTTOMLEFT", 0, 0)
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
        GameTooltip:SetText("Show AoE Rotation", 0, 0.75, 1)
        GameTooltip:AddLine(
            "Check this option to display the AoE rotation bar for abilities you flagged as 'Area of Effect Only'.", 1,
            1, 1, true)
        GameTooltip:SetMinimumWidth(150)
        GameTooltip:Show()
    end)
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation:SetScript("OnClick", function(self)
        PlaySound(1115)
        ConditionerAddOn_SavedVariables.Options.ShowAoeRotation = self:GetChecked()
    end)
    ConditionerAddOn.LoadoutFrame.ShowAoeRotation:SetScript("OnShow", function(self)
        self:SetChecked(ConditionerAddOn_SavedVariables.Options.ShowAoeRotation)
    end)

    -- STRETCH THE CONTAINER
    ConditionerAddOn.LoadoutFrame.OptionsContainer:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.AlwaysShow,
        "TOPLEFT")
    ConditionerAddOn.LoadoutFrame.OptionsContainer:SetPoint("BOTTOMRIGHT",
        ConditionerAddOn.LoadoutFrame.BackgroundFrame, "BOTTOMRIGHT", -8, 8)
    ConditionerAddOn.LoadoutFrame.BackgroundFrame:SetPoint("BOTTOM", lastFrameToStretchTo, "BOTTOM", 0,
        -20)
    -- ===================================================================================================================--
    --------------------------------------------------------OPTIONS--------------------------------------------------------
    -- ===================================================================================================================--
    -- =======================================================================================================================--
    --------------------------------------------------------DANCING MAN--------------------------------------------------------
    -- =======================================================================================================================--
    ConditionerAddOn.LoadoutFrame.DancingManShoes = CreateFrame("Frame", nil,
        ConditionerAddOn.LoadoutFrame.BackgroundFrame)
    ConditionerAddOn.LoadoutFrame.DancingManShoes:SetPoint("TOPLEFT", ConditionerAddOn.LoadoutFrame.BackgroundFrame,
        "TOPLEFT")
    ConditionerAddOn.LoadoutFrame.DancingManShoes:SetSize(ConditionerAddOn.LoadoutFrame.BackgroundFrame:GetWidth(), 10)
    ConditionerAddOn.LoadoutFrame.DancingMan = CreateFrame("PlayerModel", nil,
        ConditionerAddOn.LoadoutFrame.BackgroundFrame)
    ConditionerAddOn.LoadoutFrame.DancingMan:SetSize(100, 100)
    ConditionerAddOn.LoadoutFrame.DancingMan:SetRotation(-0.25)
    if (UnitFactionGroup("player") == "Alliance") then
        ConditionerAddOn.LoadoutFrame.DancingMan:SetDisplayInfo(37526)
        ConditionerAddOn.LoadoutFrame.DancingMan:SetPoint("BOTTOMRIGHT", ConditionerAddOn.LoadoutFrame.DancingManShoes,
            "TOPRIGHT", 20, -24)
    else
        ConditionerAddOn.LoadoutFrame.DancingMan:SetDisplayInfo(37527)
        ConditionerAddOn.LoadoutFrame.DancingMan:SetPoint("BOTTOMRIGHT", ConditionerAddOn.LoadoutFrame.DancingManShoes,
            "TOPRIGHT", 20, -20)
    end
    ConditionerAddOn.LoadoutFrame.DancingMan:SetAnimation(69)
    ConditionerAddOn.LoadoutFrame.DancingMan.CurrentAnim = 69
    ConditionerAddOn.LoadoutFrame.DancingMan:SetFrameStrata("HIGH")
    ConditionerAddOn.LoadoutFrame.DancingManShoes:SetScript("OnUpdate", function(self, elapsed)
        if (ConditionerAddOn.LoadoutFrame.DancingMan.Wounds) and (ConditionerAddOn.LoadoutFrame.DancingMan.Wounds > 0) then
            ConditionerAddOn.LoadoutFrame.DancingMan.Wounds =
                ConditionerAddOn.LoadoutFrame.DancingMan.Wounds - elapsed / 2
            if (ConditionerAddOn.LoadoutFrame.DancingMan.isDead) then
                ConditionerAddOn.LoadoutFrame.DancingMan.Acceleration =
                    ConditionerAddOn.LoadoutFrame.DancingMan.Acceleration * (1 + elapsed)
                local percentFade = math.max((ConditionerAddOn.LoadoutFrame.DancingMan.Wounds - elapsed *
                    ConditionerAddOn.LoadoutFrame.DancingMan.Acceleration) / 10, 0)
                ConditionerAddOn.LoadoutFrame.DancingMan:SetAlpha(math.min(1, percentFade))
            end
            if (ConditionerAddOn.LoadoutFrame.DancingMan.Wounds <= 0) then
                ConditionerAddOn.LoadoutFrame.DancingMan.Hitbox:EnableMouse(true)
                ConditionerAddOn.LoadoutFrame.DancingMan:SetAnimation(
                    ConditionerAddOn.LoadoutFrame.DancingMan.CurrentAnim)
                ConditionerAddOn.LoadoutFrame.DancingMan:SetAlpha(1)
                ConditionerAddOn.LoadoutFrame.DancingMan.isDead = false
            end
        else
            ConditionerAddOn.LoadoutFrame.DancingManShoes.RandomTimer =
                ConditionerAddOn.LoadoutFrame.DancingManShoes.RandomTimer or math.random(4, 8)
            ConditionerAddOn.LoadoutFrame.DancingManShoes.Timer =
                (ConditionerAddOn.LoadoutFrame.DancingManShoes.Timer or
                    -ConditionerAddOn.LoadoutFrame.DancingManShoes.RandomTimer) + elapsed
            if (ConditionerAddOn.LoadoutFrame.DancingManShoes.Timer >
                    ConditionerAddOn.LoadoutFrame.DancingManShoes.RandomTimer) then
                ConditionerAddOn.LoadoutFrame.DancingManShoes.Direction =
                    not ConditionerAddOn.LoadoutFrame.DancingManShoes.Direction
                ConditionerAddOn.LoadoutFrame.DancingManShoes.Timer = -(math.random(4, 8))
                ConditionerAddOn.LoadoutFrame.DancingMan:SetRotation(0.85 *
                    (ConditionerAddOn.LoadoutFrame.DancingManShoes
                        .Direction and 1 or -1))
                ConditionerAddOn.LoadoutFrame.DancingMan:SetAnimation(4)
                ConditionerAddOn.LoadoutFrame.DancingMan.CurrentAnim = 4
                if (ConditionerAddOn.LoadoutFrame.DancingManShoes.isWalking) then
                    ConditionerAddOn.LoadoutFrame.DancingMan:SetAnimation(69)
                    ConditionerAddOn.LoadoutFrame.DancingMan.CurrentAnim = 69
                    ConditionerAddOn.LoadoutFrame.DancingManShoes.isWalking = false
                    ConditionerAddOn.LoadoutFrame.DancingMan:SetRotation(0.25 *
                        (ConditionerAddOn.LoadoutFrame
                            .DancingManShoes.Direction and 1 or -1))
                end
                ConditionerAddOn.LoadoutFrame.DancingManShoes.RandomTimer = math.random(4, 8)
            end

            if (ConditionerAddOn.LoadoutFrame.DancingManShoes.Timer >= 0) then
                local deltaX = (ConditionerAddOn.LoadoutFrame.BackgroundFrame:GetWidth() - 60) /
                    ConditionerAddOn.LoadoutFrame.DancingManShoes.RandomTimer
                ConditionerAddOn.LoadoutFrame.DancingManShoes:SetWidth(
                    ConditionerAddOn.LoadoutFrame.DancingManShoes:GetWidth() + deltaX * elapsed *
                    (ConditionerAddOn.LoadoutFrame.DancingManShoes.Direction and 1 or -1))
                if (not ConditionerAddOn.LoadoutFrame.DancingManShoes.isWalking) then
                    ConditionerAddOn.LoadoutFrame.DancingMan:SetAnimation(4)
                    ConditionerAddOn.LoadoutFrame.DancingMan.CurrentAnim = 4
                    ConditionerAddOn.LoadoutFrame.DancingMan:SetRotation(0.85 *
                        (ConditionerAddOn.LoadoutFrame
                            .DancingManShoes.Direction and 1 or -1))
                    ConditionerAddOn.LoadoutFrame.DancingManShoes.isWalking = true
                end
            end
        end
    end)
    ConditionerAddOn.LoadoutFrame.DancingMan:SetScript("OnAnimFinished", function(self)
        if (ConditionerAddOn.LoadoutFrame.DancingMan:IsShown()) then
            if (ConditionerAddOn.LoadoutFrame.DancingMan.AnimQueue) and
                (#ConditionerAddOn.LoadoutFrame.DancingMan.AnimQueue > 0) then
                local nextAnim = ConditionerAddOn.LoadoutFrame.DancingMan.AnimQueue[#ConditionerAddOn.LoadoutFrame
                .DancingMan.AnimQueue]
                ConditionerAddOn.LoadoutFrame.DancingMan:SetAnimation(nextAnim)
                ConditionerAddOn.LoadoutFrame.DancingMan.AnimQueue[#ConditionerAddOn.LoadoutFrame.DancingMan.AnimQueue] =
                    nil
                if (not ConditionerAddOn.LoadoutFrame.DancingMan.isDead) then
                    ConditionerAddOn.LoadoutFrame.DancingMan.Wounds = 0
                    ConditionerAddOn.LoadoutFrame.DancingMan:SetAnimation(
                        ConditionerAddOn.LoadoutFrame.DancingMan.CurrentAnim)
                end
            end
        end
    end)
    ConditionerAddOn.LoadoutFrame.DancingMan.Hitbox =
        CreateFrame("Frame", nil, ConditionerAddOn.LoadoutFrame.DancingMan)
    ConditionerAddOn.LoadoutFrame.DancingMan.Hitbox:SetPoint("CENTER", ConditionerAddOn.LoadoutFrame.DancingMan,
        "CENTER")
    ConditionerAddOn.LoadoutFrame.DancingMan.Hitbox:SetSize(20, 50)
    ConditionerAddOn.LoadoutFrame.DancingMan.Hitbox:EnableMouse(true)
    ConditionerAddOn.LoadoutFrame.DancingMan.Hitbox:SetScript("OnMouseDown", function(self, button, down)
        ConditionerAddOn.LoadoutFrame.DancingMan.Wounds = (ConditionerAddOn.LoadoutFrame.DancingMan.Wounds or 0) + 1
        if (ConditionerAddOn.LoadoutFrame.DancingMan.Wounds > 10) then
            ConditionerAddOn.LoadoutFrame.DancingMan.AnimQueue = {}
            ConditionerAddOn.LoadoutFrame.DancingMan:SetAnimation(230)
            ConditionerAddOn.LoadoutFrame.DancingMan.Hitbox:EnableMouse(false)
            ConditionerAddOn.LoadoutFrame.DancingMan.Acceleration = 5
            ConditionerAddOn.LoadoutFrame.DancingMan.isDead = true
        else
            ConditionerAddOn.LoadoutFrame.DancingMan:SetAnimation(8)
            ConditionerAddOn.LoadoutFrame.DancingMan.AnimQueue =
                ConditionerAddOn.LoadoutFrame.DancingMan.AnimQueue or {}
            table.insert(ConditionerAddOn.LoadoutFrame.DancingMan.AnimQueue,
                ConditionerAddOn.LoadoutFrame.DancingMan.CurrentAnim)
        end
    end)
    -- =======================================================================================================================--
    --------------------------------------------------------DANCING MAN--------------------------------------------------------
    -- =======================================================================================================================--
end

-- ============================================================================================================================--
-----------------------------------------------------------INITIALIZE-----------------------------------------------------------
-- ============================================================================================================================--
function ConditionerAddOn.EventHandler:PLAYER_ENTERING_WORLD(...)
    ConditionerAddOn:ClearCurrentLoadout()
    local currentPackage = ConditionerAddOn:GetLoadoutPackageByID()
    ConditionerAddOn:ApplyLoadout(currentPackage)
    if (ConditionerAddOn.LoadoutFrame) then
        SetPortraitTexture(ConditionerAddOn.LoadoutFrame.DragTexture, "player")
    end
    ConditionerAddOn:ResizeTrackers()
    ConditionerAddOn:CacheCurrentSpecSpells()
end

if (not isClassic()) then
    function ConditionerAddOn.EventHandler:PLAYER_SPECIALIZATION_CHANGED(...)
        if (select(1, ...) == "player") then
            ConditionerAddOn:ClearCurrentLoadout()
            local currentPackage = ConditionerAddOn:GetLoadoutPackageByID()
            ConditionerAddOn:ApplyLoadout(currentPackage)
            ConditionerAddOn.LoadoutFrame.DropDown:Hide()
            ConditionerAddOn.LoadoutFrame.DropDown:Show()
            ConditionerAddOn.SharedConditionerFrame:Hide()
            if (ConditionerAddOn.CurrentPriorityButton) then
                -- ActionButton_HideOverlayGlow(ConditionerAddOn.CurrentPriorityButton)
            end
            SetPortraitTexture(ConditionerAddOn.LoadoutFrame.DragTexture, "player")
            ConditionerAddOn:CacheCurrentSpecSpells()
        end
    end
end



function ConditionerAddOn.EventHandler:ADDON_LOADED(...)
    local AddOnName = select(1, ...)
    if (AddOnName == "Conditioner") then
        ConditionerAddOn_SavedVariables = ConditionerAddOn_SavedVariables or {}
        ConditionerAddOn_SavedVariables_Loadouts = ConditionerAddOn_SavedVariables_Loadouts or {
            [-1] = {
                name = "Basic Rotation",
                value = "",
                spec = 0
            },
            [0] = {
                name = "None",
                value = "",
                spec = 0
            }
        }
        ConditionerAddOn_SavedVariables.CurrentLoadouts = ConditionerAddOn_SavedVariables.CurrentLoadouts or {}
        ConditionerAddOn:FixupSavedVariables()
        ConditionerAddOn:FixupLoadoutGaps()
        ConditionerAddOn_SavedVariables.Options = ConditionerAddOn_SavedVariables.Options or {
            TrackedFrameAnchorCoords = {
                x = false,
                y = false
            },
            AnchorDirection = 0,
            TrackedFrameSize = 100,
            TaperSize = 80,
            NumTrackedFrames = 5,
            Opacity = 100,
            ShowSwingTimers = false,
            HideRangedSwingTimer = false,
            OnlyDisplayInCombat = false
        }
        -- new options
        if (not ConditionerAddOn_SavedVariables.Options.AoeRotationAnchor) then
            ConditionerAddOn_SavedVariables.Options.AoeRotationAnchor = {
                x = false,
                y = false
            }
        end

        ConditionerAddOn:Init()
    end
end

if (isClassic()) then
    ConditionerAddOn.castInfo = {}
    ConditionerAddOn.currentTargetGuid = nil

    function ConditionerAddOn:FindSpellIdByName(name)
        if (not ConditionerAddOn.castInfo[name]) then
            for i = 1, 999999, 1 do
                local spellName, _ = GetSpellInfo(i)
                if (name == spellName) then
                    ConditionerAddOn.castInfo[name] = i
                    return ConditionerAddOn.castInfo[name]
                end
            end
        else
            return ConditionerAddOn.castInfo[name]
        end
    end

    function ConditionerAddOn:HandleCastBars(...)
        if (select(1, ...) == "target") then
            local spellName, _, spellIcon, castTime, _, _, spellId = GetSpellInfo(select(3, ...))
            local castStart = GetTime() * 1000
            local castEnd = castStart + castTime

            currentCastingInfo[1] = spellName
            currentCastingInfo[3] = spellIcon
            currentCastingInfo[4] = castStart
            currentCastingInfo[5] = castEnd
            currentCastingInfo[8] = false
            currentCastingInfo[9] = spellId
            currentCastingInfo[10] = UnitGUID(select(1, ...))
        end
    end

    function ConditionerAddOn.EventHandler:UNIT_SPELLCAST_SENT(...)
        if (isClassic()) then
            local spellId = select(4, ...)
            local spellName = GetSpellInfo(spellId)
            if (not ConditionerAddOn.castInfo[spellName]) then
                ConditionerAddOn.castInfo[spellName] = spellId
            end
        end
    end

    function ConditionerAddOn.EventHandler:PLAYER_TARGET_CHANGED(...)
        ClearCastingInfo(ConditionerAddOn.currentTargetGuid)
        ConditionerAddOn.currentTargetGuid = UnitGUID("target")
    end

    function ConditionerAddOn.EventHandler:UNIT_SPELLCAST_START(...)
        if (isClassic()) then
            ConditionerAddOn:HandleCastBars(...)
        end
    end

    function ConditionerAddOn.EventHandler:UNIT_SPELLCAST_STOP(...)
        if (isClassic()) then
            ClearCastingInfo(UnitGUID(select(1, ...)))
        end
    end

    function ConditionerAddOn.EventHandler:UNIT_SPELLCAST_CHANNEL_START(...)
        if (isClassic()) then
            ConditionerAddOn:HandleCastBars(...)
        end
    end

    function ConditionerAddOn.EventHandler:UNIT_SPELLCAST_CHANNEL_STOP(...)
        if (isClassic()) then
            ClearCastingInfo(select(1, ...))
        end
    end
end

function ConditionerAddOn:ClassicCastBars()
    if (isClassic() and CombatLogGetCurrentEventInfo) then
        local eventArgs = { CombatLogGetCurrentEventInfo() }
        local subEvent = eventArgs[2]
        local attackerGuid = eventArgs[4]
        local spellName = eventArgs[13]

        if (subEvent == "SPELL_INTERRUPT" and attackerGuid == UnitGUID("player")) then
            ClearCastingInfo(UnitGUID("target"))
        end
        if (subEvent == "SPELL_CAST_STOP" or subEvent == "SPELL_CAST_SUCCESS") then
            ConditionerAddOn:FindSpellIdByName(spellName)
            ClearCastingInfo(attackerGuid)
        end
        if (subEvent == "SPELL_CAST_START" and ConditionerAddOn.currentTargetGuid == attackerGuid) then
            if (ConditionerAddOn:FindSpellIdByName(spellName)) then
                -- this is the thing I am targeting
                ConditionerAddOn:HandleCastBars("target", _, ConditionerAddOn.castInfo[spellName])
            end
        end
    end
end

function ConditionerAddOn.EventHandler:COMBAT_LOG_EVENT_UNFILTERED(...)
    ConditionerAddOn:SpellCacheWatcher(...)
    ConditionerAddOn:HandleSwingTimerMelee(...)
    ConditionerAddOn:ClassicCastBars()
end

function ConditionerAddOn.EventHandler:UNIT_SPELLCAST_SUCCEEDED(...)
    ConditionerAddOn:HandleSwingTimerRanged(...)
end

--[[
function ConditionerAddOn.EventHandler:ADDON_ACTION_FORBIDDEN(...)

end

function ConditionerAddOn.EventHandler:ADDON_ACTION_BLOCKED(...)

end
]]
ConditionerAddOn:SetScript("OnEvent", function(self, event, ...)
    ConditionerAddOn.EventHandler[event](self, ...)
end)
for k, v in pairs(ConditionerAddOn.EventHandler) do
    ConditionerAddOn:RegisterEvent(k)
end
ConditionerAddOn:SetScript("OnUpdate", function(self, elapsed)
    ConditionerAddOn:OnUpdate(elapsed)
    ConditionerAddOn:UpdateSwingTimers(elapsed)
    ConditionerAddOn:UpdateCastBar(elapsed)

    if (closeResultsBox and ConditionerAddOn.SharedConditionerFrame.ResultsBox) then
        if (ConditionerAddOn.SharedConditionerFrame.ResultsBox:IsShown()) then
            ConditionerAddOn.SharedConditionerFrame.ResultsBox:ClearResults()
            ConditionerAddOn.SharedConditionerFrame.ResultsBox:FixBackground()
        end

        if (ConditionerAddOn.SharedConditionerFrame.EditBoxes and ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]) then
            local strippedString = ConditionerAddOn.SharedConditionerFrame.EditBoxes[3]:GetText():gsub("_", " ")
            ConditionerAddOn:SetCurrentCondition('activeAuraString', strippedString)
        end

        closeResultsBox = false
    end

    -- second search box shameful copy/paste
    if (closeResultsBox2 and ConditionerAddOn.SharedConditionerFrame.ResultsBox2) then
        if (ConditionerAddOn.SharedConditionerFrame.ResultsBox2:IsShown()) then
            ConditionerAddOn.SharedConditionerFrame.ResultsBox2:ClearResults()
            ConditionerAddOn.SharedConditionerFrame.ResultsBox2:FixBackground()
        end

        if (ConditionerAddOn.SharedConditionerFrame.EditBoxes and ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]) then
            local strippedString = ConditionerAddOn.SharedConditionerFrame.EditBoxes[9]:GetText():gsub("_", " ")
            ConditionerAddOn:SetCurrentCondition('myActiveAura', strippedString)
        end

        closeResultsBox2 = false
    end
end)
