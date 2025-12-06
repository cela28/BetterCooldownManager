local _, BCDM = ...
BCDM.CustomFrames = BCDM.CustomFrames or {}

local DefensiveSpells = {
    -- Monk
    -- Brewmaster
    [1241059] = true,       -- Celestial Infusion
    [115203] = true,        -- Fortifying Brew
    [322507] = true,        -- Celestial Brew
    -- Windwalker
    [122470] = true,        -- Touch of Karma
}

function CreateCustomIcon(spellId)
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local DefensiveDB = CooldownManagerDB.Defensive
    if not spellId then return end
    if not C_SpellBook.IsSpellKnown(spellId) then return end

    local customSpellIcon = CreateFrame("Button", "BCDM_Custom_" .. spellId, UIParent, "BackdropTemplate")
    customSpellIcon:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    customSpellIcon:SetBackdropBorderColor(0, 0, 0, 1)
    customSpellIcon:SetSize(DefensiveDB.IconSize[1], DefensiveDB.IconSize[2])
    customSpellIcon:SetPoint(unpack(DefensiveDB.Anchors))
    customSpellIcon:RegisterEvent("SPELL_UPDATE_COOLDOWN")

    customSpellIcon.Cooldown = CreateFrame("Cooldown", nil, customSpellIcon, "CooldownFrameTemplate")
    customSpellIcon.Cooldown:SetAllPoints(customSpellIcon)
    customSpellIcon.Cooldown:SetDrawEdge(false)
    customSpellIcon.Cooldown:SetDrawSwipe(true)
    customSpellIcon.Cooldown:SetSwipeColor(0, 0, 0, 0.8)
    customSpellIcon.Cooldown:SetHideCountdownNumbers(false)
    customSpellIcon.Cooldown:SetReverse(false)

    customSpellIcon:HookScript("OnEvent", function(self, event, ...)
        if event == "SPELL_UPDATE_COOLDOWN" then
            local cooldownData = C_Spell.GetSpellCooldown(spellId)
            customSpellIcon.Cooldown:SetCooldown(cooldownData.startTime, cooldownData.duration)
        end
    end)

    customSpellIcon.Icon = customSpellIcon:CreateTexture(nil, "BACKGROUND")
    customSpellIcon.Icon:SetPoint("TOPLEFT", customSpellIcon, "TOPLEFT", 1, -1)
    customSpellIcon.Icon:SetPoint("BOTTOMRIGHT", customSpellIcon, "BOTTOMRIGHT", -1, 1)
    customSpellIcon.Icon:SetTexCoord((GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5, (GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5)
    customSpellIcon.Icon:SetTexture(C_Spell.GetSpellInfo(spellId).iconID)

    return customSpellIcon
end

local LayoutConfig = {
    TOPLEFT     = { anchor="TOPLEFT",   offsetMultiplier=0   },
    TOP         = { anchor="TOP",       offsetMultiplier=0   },
    TOPRIGHT    = { anchor="TOPRIGHT",  offsetMultiplier=0   },
    BOTTOMLEFT  = { anchor="TOPLEFT",   offsetMultiplier=1   },
    BOTTOM      = { anchor="TOP",       offsetMultiplier=1   },
    BOTTOMRIGHT = { anchor="TOPRIGHT",  offsetMultiplier=1   },
    CENTER      = { anchor="CENTER",    offsetMultiplier=0.5, isCenter=true },
    LEFT        = { anchor="LEFT",      offsetMultiplier=0.5, isCenter=true },
    RIGHT       = { anchor="RIGHT",     offsetMultiplier=0.5, isCenter=true },
}

function LayoutCustomIcons()
    local DefensiveDB = BCDM.db.profile.Defensive
    local icons = BCDM.DefensiveBar
    if #icons == 0 then return end
    if not BCDM.DefensiveContainer then BCDM.DefensiveContainer = CreateFrame("Frame", "DefensiveCooldownViewer", UIParent) end

    local defensiveContainer = BCDM.DefensiveContainer
    local spacing = DefensiveDB.Spacing
    local iconW   = icons[1]:GetWidth()
    local iconH   = icons[1]:GetHeight()
    local totalW  = (iconW + spacing) * #icons - spacing

    defensiveContainer:SetSize(totalW, iconH)
    local layoutConfig = LayoutConfig[DefensiveDB.Anchors[1]]

    local offsetX = totalW * layoutConfig.offsetMultiplier
    if layoutConfig.isCenter then offsetX = offsetX - iconW / 2 end

    defensiveContainer:ClearAllPoints()
    defensiveContainer:SetPoint(DefensiveDB.Anchors[1], DefensiveDB.Anchors[2], DefensiveDB.Anchors[3], DefensiveDB.Anchors[4], DefensiveDB.Anchors[5])

    local growLeft  = (DefensiveDB.GrowthDirection == "LEFT")
    for i, icon in ipairs(icons) do
        icon:ClearAllPoints()
        if i == 1 then
            if growLeft then
                icon:SetPoint("RIGHT", defensiveContainer, "RIGHT", 0, 0)
            else
                icon:SetPoint("LEFT", defensiveContainer, "LEFT", 0, 0)
            end
        else
            local previousIcon = icons[i-1]
            if growLeft then
                icon:SetPoint("RIGHT", previousIcon, "LEFT", -spacing, 0)
            else
                icon:SetPoint("LEFT", previousIcon, "RIGHT", spacing, 0)
            end
        end
    end

    defensiveContainer:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    defensiveContainer:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
            BCDM:ResetCustomIcons()
        end
    end)
end

function BCDM:SetupCustomIcons()
    wipe(BCDM.CustomFrames)
    wipe(BCDM.DefensiveBar)
    for spellId in pairs(DefensiveSpells) do
        local frame = CreateCustomIcon(spellId)
        BCDM.CustomFrames[spellId] = frame
        table.insert(BCDM.DefensiveBar, frame)
    end
    LayoutCustomIcons()
end

function BCDM:ResetCustomIcons()
    for spellId, frame in pairs(BCDM.CustomFrames) do
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent(nil)
        _G["BCDM_Custom_" .. spellId] = nil
    end
    BCDM.CustomFrames = {}
    wipe(BCDM.DefensiveBar)
    for spellId in pairs(DefensiveSpells) do
        local frame = CreateCustomIcon(spellId)
        BCDM.CustomFrames[spellId] = frame
        table.insert(BCDM.DefensiveBar, frame)
    end
    LayoutCustomIcons()
end


function BCDM:UpdateDefensiveIcons()
    local CooldownManagerDB = BCDM.db.profile
    local GeneralDB = CooldownManagerDB.General
    local DefensiveDB = CooldownManagerDB.Defensive
    BCDM.DefensiveContainer:ClearAllPoints()
    BCDM.DefensiveContainer:SetPoint(DefensiveDB.Anchors[1], DefensiveDB.Anchors[2], DefensiveDB.Anchors[3], DefensiveDB.Anchors[4], DefensiveDB.Anchors[5])
    for _, icon in ipairs(BCDM.DefensiveBar) do
        if icon then
            icon:SetSize(DefensiveDB.IconSize[1], DefensiveDB.IconSize[2])
            icon.Icon:SetTexCoord((GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5, (GeneralDB.IconZoom) * 0.5, 1 - (GeneralDB.IconZoom) * 0.5)
        end
    end
    LayoutCustomIcons()
end