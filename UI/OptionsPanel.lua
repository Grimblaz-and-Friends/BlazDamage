-- UI/OptionsPanel.lua
-- Blizzard Settings API options panel. UI layer — WoW API permitted.

local _, BD = ...
if type(BD) ~= "table" then BD = {} end

local OptionsPanel = {}

-- Category registered at file-load time (safe before ADDON_LOADED)
local category = Settings.RegisterVerticalLayoutCategory("BlazDamage")
Settings.RegisterAddOnCategory(category)
BD.optionsCategoryID = category:GetID()

function OptionsPanel.init()
    -- Called from Core.lua ADDON_LOADED handler, after BD.config is assigned.
    -- Uses 5-arg RegisterAddOnSetting (no variableTable) with explicit BD.config
    -- sync in each callback. Keys are prefixed "bd_" to avoid CVar namespace
    -- conflicts with Blizzard or other addon settings.

    -- [OVERLAY SECTION]
    local function getMetricOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("avg", "Average")
        container:Add("dps", "DPS")
        container:Add("dpsc", "DPS (Cost)")
        container:Add("dpm", "DPM")
        return container:GetData()
    end
    local metricSetting = Settings.RegisterAddOnSetting(
        category, "Overlay Metric", "bd_metric",
        Settings.VarType.String, BD.config.metric
    )
    Settings.CreateDropdown(category, metricSetting, getMetricOptions,
        "Which metric to display on action bar buttons.")
    metricSetting:SetValueChangedCallback(function()
        BD.config.metric = metricSetting:GetValue()
        if BD.OverlayRenderer then BD.OverlayRenderer.refreshAll() end
    end)

    local showOverlaysSetting = Settings.RegisterAddOnSetting(
        category, "Show Overlays", "bd_showOverlays",
        Settings.VarType.Boolean, BD.config.showOverlays
    )
    Settings.CreateCheckbox(category, showOverlaysSetting,
        "Show damage/healing metrics on action bar buttons.")
    showOverlaysSetting:SetValueChangedCallback(function()
        BD.config.showOverlays = showOverlaysSetting:GetValue()
        if BD.OverlayRenderer then BD.OverlayRenderer.refreshAll() end
    end)

    local fontSizeSetting = Settings.RegisterAddOnSetting(
        category, "Overlay Font Size", "bd_overlayFontSize",
        Settings.VarType.Number, BD.config.overlayFontSize
    )
    local sliderOptions = Settings.CreateSliderOptions(8, 20, 1)
    Settings.CreateSlider(category, fontSizeSetting, sliderOptions, "Font size for overlay text.")
    fontSizeSetting:SetValueChangedCallback(function()
        BD.config.overlayFontSize = fontSizeSetting:GetValue()
        if BD.OverlayRenderer and BD.OverlayRenderer.applyStyle then
            BD.OverlayRenderer.applyStyle()
        end
    end)

    local function getPositionOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("TOPLEFT", "Top Left")
        container:Add("TOPRIGHT", "Top Right")
        container:Add("BOTTOMLEFT", "Bottom Left")
        container:Add("BOTTOMRIGHT", "Bottom Right")
        return container:GetData()
    end
    local positionSetting = Settings.RegisterAddOnSetting(
        category, "Overlay Position", "bd_overlayPosition",
        Settings.VarType.String, BD.config.overlayPosition
    )
    Settings.CreateDropdown(category, positionSetting, getPositionOptions,
        "Where to anchor the overlay text on each button.")
    positionSetting:SetValueChangedCallback(function()
        BD.config.overlayPosition = positionSetting:GetValue()
        if BD.OverlayRenderer and BD.OverlayRenderer.applyStyle then
            BD.OverlayRenderer.applyStyle()
        end
    end)

    -- [TOOLTIP SECTION]
    local showTooltipsSetting = Settings.RegisterAddOnSetting(
        category, "Show Tooltips", "bd_showTooltips",
        Settings.VarType.Boolean, BD.config.showTooltips
    )
    Settings.CreateCheckbox(category, showTooltipsSetting,
        "Show damage/healing metrics in spell tooltips.")
    showTooltipsSetting:SetValueChangedCallback(function()
        BD.config.showTooltips = showTooltipsSetting:GetValue()
    end)

    local tooltipShowAvgSetting = Settings.RegisterAddOnSetting(
        category, "Tooltip: Average", "bd_tooltipShowAvg",
        Settings.VarType.Boolean, BD.config.tooltipShowAvg
    )
    Settings.CreateCheckbox(category, tooltipShowAvgSetting,
        "Show average damage/healing in tooltips.")
    tooltipShowAvgSetting:SetValueChangedCallback(function()
        BD.config.tooltipShowAvg = tooltipShowAvgSetting:GetValue()
    end)

    local tooltipShowDpsSetting = Settings.RegisterAddOnSetting(
        category, "Tooltip: DPS", "bd_tooltipShowDps",
        Settings.VarType.Boolean, BD.config.tooltipShowDps
    )
    Settings.CreateCheckbox(category, tooltipShowDpsSetting, "Show DPS in tooltips.")
    tooltipShowDpsSetting:SetValueChangedCallback(function()
        BD.config.tooltipShowDps = tooltipShowDpsSetting:GetValue()
    end)

    local tooltipShowDpscSetting = Settings.RegisterAddOnSetting(
        category, "Tooltip: DPS (Cost)", "bd_tooltipShowDpsc",
        Settings.VarType.Boolean, BD.config.tooltipShowDpsc
    )
    Settings.CreateCheckbox(category, tooltipShowDpscSetting,
        "Show DPS per resource cost in tooltips.")
    tooltipShowDpscSetting:SetValueChangedCallback(function()
        BD.config.tooltipShowDpsc = tooltipShowDpscSetting:GetValue()
    end)

    local tooltipShowCritSetting = Settings.RegisterAddOnSetting(
        category, "Tooltip: Crit", "bd_tooltipShowCrit",
        Settings.VarType.Boolean, BD.config.tooltipShowCrit
    )
    Settings.CreateCheckbox(category, tooltipShowCritSetting,
        "Show crit chance % in tooltips.")
    tooltipShowCritSetting:SetValueChangedCallback(function()
        BD.config.tooltipShowCrit = tooltipShowCritSetting:GetValue()
    end)

    local tooltipShowDpmSetting = Settings.RegisterAddOnSetting(
        category, "Tooltip: Per Resource", "bd_tooltipShowDpm",
        Settings.VarType.Boolean, BD.config.tooltipShowDpm
    )
    Settings.CreateCheckbox(category, tooltipShowDpmSetting,
        "Show damage/healing per resource in tooltips.")
    tooltipShowDpmSetting:SetValueChangedCallback(function()
        BD.config.tooltipShowDpm = tooltipShowDpmSetting:GetValue()
    end)

    -- [MISC SECTION]
    local function getDiscoveryOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("auto", "Auto")
        container:Add("update", "Update Hook")
        return container:GetData()
    end
    local discoveryModeSetting = Settings.RegisterAddOnSetting(
        category, "Discovery Mode", "bd_discoveryMode",
        Settings.VarType.String, BD.config.discoveryMode
    )
    Settings.CreateDropdown(category, discoveryModeSetting, getDiscoveryOptions,
        "Requires /reload to take effect.")
    discoveryModeSetting:SetValueChangedCallback(function()
        BD.config.discoveryMode = discoveryModeSetting:GetValue()
    end)

    local showPerfSetting = Settings.RegisterAddOnSetting(
        category, "Show Performance Info", "bd_showPerf",
        Settings.VarType.Boolean, BD.config.showPerf
    )
    Settings.CreateCheckbox(category, showPerfSetting, "Log performance timing to chat.")
    showPerfSetting:SetValueChangedCallback(function()
        BD.config.showPerf = showPerfSetting:GetValue()
    end)
end

BD.OptionsPanel = OptionsPanel
