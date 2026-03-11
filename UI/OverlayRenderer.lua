-- UI/OverlayRenderer.lua
-- Overlay creation and data pipeline for actionbar buttons. UI layer — WoW API permitted.

local _, BD = ...
if type(BD) ~= "table" then BD = {} end

local OverlayRenderer = {}

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

    if not slot or not HasAction(slot) then
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
    local stats = {
        critChance   = playerStats.critChance,
        critMult     = playerStats.critMult,
        gcd          = playerStats.gcd,
        castTime     = spellStats.castTime,
        resourceCost = spellStats.resourceCost,
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

function OverlayRenderer.attachOverlay(button)
    if not button then return end
    if trackedButtons[button] then return end

    local slot = button.action
    local overlay = button:CreateFontString(nil, "OVERLAY")
    overlay:SetFontObject(NumberFontNormalSmall)
    overlay:SetTextColor(1, 1, 1)
    overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)

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
    for button, entry in pairs(trackedButtons) do
        updateButton(button, entry)
    end
end

function OverlayRenderer.refreshSlot(slot)
    if BD.config and BD.config.showOverlays == false then return end
    local button = slotToButton[slot]
    if button then
        local entry = trackedButtons[button]
        if entry then
            updateButton(button, entry)
        end
    end
end

BD.OverlayRenderer = OverlayRenderer
