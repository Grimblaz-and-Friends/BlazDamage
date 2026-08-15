-- UI/OverlayRenderer.lua
-- Overlay creation and data pipeline for actionbar buttons. UI layer — WoW API permitted.

local _, BD = ...
if type(BD) ~= "table" then BD = {} end

local OverlayRenderer = {}

local POSITION_OFFSETS = {
    TOPLEFT     = { 2, -2},
    TOPRIGHT    = {-2, -2},
    BOTTOMLEFT  = { 2,  2},
    BOTTOMRIGHT = {-2,  2},
}

local trackedButtons = {}   -- keyed by button frame → { overlay = FontString, slot = number }
local slotToButton   = {}   -- keyed by slot number → button frame (reverse index)

local function updateButton(button, entry)
    local overlay = entry.overlay
    local slot = button.action

    -- Update slot in case button.action changed
    if slot ~= entry.slot then
        if entry.slot then slotToButton[entry.slot] = nil end
        entry.slot = slot
        if slot then slotToButton[slot] = button end
    end

    if not slot or not C_ActionBar.HasAction(slot) then
        overlay:Hide()
        return
    end

    local actionType, id = GetActionInfo(slot)
    if actionType ~= "spell" then
        overlay:Hide()
        return
    end

    local spellStats = BD.StatCollector.getSpellStats(id)
    if not spellStats or not spellStats.description then
        overlay:Hide()
        return
    end

    local parsed = BD.DescriptionParser.parse(spellStats.description)
    if not parsed or #parsed == 0 then
        overlay:Hide()
        return
    end

    local playerStats = BD.StatCollector.getPlayerStats()
    if not playerStats then
        -- Stats unreadable (secret under combat restrictions) and nothing cached from out of
        -- combat: hide rather than show a number we cannot stand behind.
        overlay:Hide()
        return
    end
    local stats = {
        critChance   = playerStats.critChance,
        critMult     = playerStats.critMult,
        gcd          = playerStats.gcd,
        castTime     = spellStats.castTime,
        resourceCost = spellStats.resourceCost,
        cooldown     = spellStats.cooldown,
    }
    local result = BD.Calculator.computeMetrics(parsed, stats)
    local metric = BD.config and BD.config.metric or BD.defaults.metric
    local value = BD.Calculator.resolveMetric(result, metric)
    if not value then
        overlay:Hide()
        return
    end

    overlay:SetText(BD.Calculator.formatNumber(value))
    overlay:Show()
end

function OverlayRenderer.applyStyle()
    if not BD.config then return end
    local fontSize = math.max(8, math.min(20, BD.config.overlayFontSize))
    local rawPos = BD.config.overlayPosition
    local pos = POSITION_OFFSETS[rawPos] and rawPos or BD.defaults.overlayPosition
    local offsets = POSITION_OFFSETS[pos]
    for button, entry in pairs(trackedButtons) do
        local overlay = entry.overlay
        overlay:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
        overlay:ClearAllPoints()
        overlay:SetPoint(pos, button, pos, offsets[1], offsets[2])
    end
end

function OverlayRenderer.attachOverlay(button)
    if not button then return end
    if trackedButtons[button] then return end

    local slot = button.action
    local overlay = button:CreateFontString(nil, "OVERLAY")
    local fontSize = math.max(8, math.min(20,
        (BD.config and BD.config.overlayFontSize or BD.defaults.overlayFontSize)))
    local rawPos = BD.config and BD.config.overlayPosition or BD.defaults.overlayPosition
    local pos = POSITION_OFFSETS[rawPos] and rawPos or BD.defaults.overlayPosition
    local offsets = POSITION_OFFSETS[pos]
    overlay:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    overlay:SetTextColor(1, 1, 1)
    overlay:SetPoint(pos, button, pos, offsets[1], offsets[2])

    trackedButtons[button] = { overlay = overlay, slot = slot }
    if slot then slotToButton[slot] = button end
end

function OverlayRenderer.refreshAll()
    if BD.config and BD.config.showOverlays == false then
        for _, entry in pairs(trackedButtons) do
            entry.overlay:Hide()
        end
        return
    end
    local perfEnabled = BD.config and BD.config.showPerf
    if perfEnabled then debugprofilestart() end
    for button, entry in pairs(trackedButtons) do
        updateButton(button, entry)
    end
    if perfEnabled then
        local elapsed = debugprofilestop()
        local count = 0
        for _ in pairs(trackedButtons) do count = count + 1 end
        print(BD.PREFIX .. string.format(" refreshAll: %.3fms (%d buttons)", elapsed, count))
    end
end

function OverlayRenderer.refreshSlot(slot)
    if BD.config and BD.config.showOverlays == false then return end
    local button = slotToButton[slot]
    if button then
        local entry = trackedButtons[button]
        if entry then
            local perfEnabled = BD.config and BD.config.showPerf
            if perfEnabled then debugprofilestart() end
            updateButton(button, entry)
            if perfEnabled then
                local elapsed = debugprofilestop()
                print(BD.PREFIX .. string.format(" refreshSlot[%d]: %.3fms", slot, elapsed))
            end
        end
    end
end

BD.OverlayRenderer = OverlayRenderer
