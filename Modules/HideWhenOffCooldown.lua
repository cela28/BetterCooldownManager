local _, BCDM = ...

-- Module state
local isEnabled = false
local eventFrame = nil
local hooksSetup = false

-- Viewers to manage visibility for
local VIEWERS = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
}

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

-- Extract spell ID from icon frame's cooldownInfo
-- Pattern from DisableAuraOverlay.lua
local function GetSpellID(frame)
    local info = frame and frame.cooldownInfo
    return info and (info.overrideSpellID or info.spellID)
end

--------------------------------------------------------------------------------
-- Core Visibility Logic
--------------------------------------------------------------------------------

-- Update visibility for all icons in a specific viewer
-- Returns early if viewer doesn't exist or feature is disabled for that viewer
local function UpdateIconVisibility(viewerName)
    local viewer = _G[viewerName]
    if not viewer then return end

    -- Check if feature is enabled for this specific viewer
    local featureEnabled = BCDM:IsHideWhenOffCooldownEnabled(viewerName)

    -- Iterate all icon children
    for _, icon in ipairs({ viewer:GetChildren() }) do
        if icon and icon.cooldownInfo then
            -- If feature disabled, restore all icons to visible
            if not featureEnabled then
                icon:SetAlpha(1)
            else
                -- Get spell ID from icon
                local spellID = GetSpellID(icon)

                -- Fail-show: if no valid spell ID, keep visible
                if not spellID or spellID == 0 then
                    icon:SetAlpha(1)
                else
                    -- Check cooldown state
                    local isOnCooldown = BCDM:IsSpellOnCooldown(spellID)
                    -- Visible when on cooldown, hidden when off cooldown
                    icon:SetAlpha(isOnCooldown and 1 or 0)
                end
            end
        end
    end
end

-- Update all supported viewers
local function UpdateAllViewers()
    if not isEnabled then return end

    for _, viewerName in ipairs(VIEWERS) do
        UpdateIconVisibility(viewerName)
    end
end

--------------------------------------------------------------------------------
-- Hook and Event Setup
--------------------------------------------------------------------------------

-- Hook into RefreshLayout to update visibility when layout changes
local function SetupRefreshLayoutHooks()
    if hooksSetup then return end

    for _, viewerName in ipairs(VIEWERS) do
        local viewer = _G[viewerName]
        if viewer and viewer.RefreshLayout then
            hooksecurefunc(viewer, "RefreshLayout", function()
                UpdateIconVisibility(viewerName)
            end)
        end
    end

    hooksSetup = true
end

-- Create and configure event frame for cooldown updates
local function SetupEventFrame()
    if eventFrame then return end

    eventFrame = CreateFrame("Frame", "BCDM_HideWhenOffCooldownFrame")

    eventFrame:SetScript("OnEvent", function()
        UpdateAllViewers()
    end)
end

-- Register events for cooldown tracking
local function RegisterEvents()
    if not eventFrame then return end

    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end

-- Unregister all events
local function UnregisterEvents()
    if not eventFrame then return end

    eventFrame:UnregisterAllEvents()
end

-- Restore all icons to visible state
local function RestoreAllIcons()
    for _, viewerName in ipairs(VIEWERS) do
        local viewer = _G[viewerName]
        if viewer then
            for _, icon in ipairs({ viewer:GetChildren() }) do
                if icon then
                    icon:SetAlpha(1)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- Enable the hide-when-off-cooldown feature
function BCDM:EnableHideWhenOffCooldown()
    isEnabled = true

    SetupEventFrame()
    SetupRefreshLayoutHooks()
    RegisterEvents()

    -- Apply initial state
    UpdateAllViewers()
end

-- Disable the hide-when-off-cooldown feature
function BCDM:DisableHideWhenOffCooldown()
    isEnabled = false

    UnregisterEvents()
    RestoreAllIcons()
end

-- Refresh visibility (call when settings change)
function BCDM:RefreshHideWhenOffCooldown()
    if isEnabled then
        UpdateAllViewers()
    end
end
