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
        category, "BlazDamage_metric", "metric",
        BD.config, Settings.VarType.String, "Overlay Metric", BD.defaults.metric
    )
    Settings.CreateDropdown(category, metricSetting, getMetricOptions,
        "Which metric to display on action bar buttons.")
    metricSetting:SetValueChangedCallback(function()
        BD.config.metric = metricSetting:GetValue()
        if BD.OverlayRenderer then BD.OverlayRenderer.refreshAll() end
    end)

    local showOverlaysSetting = Settings.RegisterAddOnSetting(
        category, "BlazDamage_showOverlays", "showOverlays",
        BD.config, Settings.VarType.Boolean, "Show Overlays", BD.defaults.showOverlays
    )
    Settings.CreateCheckbox(category, showOverlaysSetting,
        "Show damage/healing metrics on action bar buttons.")
    showOverlaysSetting:SetValueChangedCallback(function()
        BD.config.showOverlays = showOverlaysSetting:GetValue()
        if BD.OverlayRenderer then BD.OverlayRenderer.refreshAll() end
    end)

    local fontSizeSetting = Settings.RegisterAddOnSetting(
        category, "BlazDamage_overlayFontSize", "overlayFontSize",
        BD.config, Settings.VarType.Number, "Overlay Font Size", BD.defaults.overlayFontSize
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
        category, "BlazDamage_overlayPosition", "overlayPosition",
        BD.config, Settings.VarType.String, "Overlay Position", BD.defaults.overlayPosition
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
        category, "BlazDamage_showTooltips", "showTooltips",
        BD.config, Settings.VarType.Boolean, "Show Tooltips", BD.defaults.showTooltips
    )
    Settings.CreateCheckbox(category, showTooltipsSetting,
        "Show damage/healing metrics in spell tooltips.")
    showTooltipsSetting:SetValueChangedCallback(function()
        BD.config.showTooltips = showTooltipsSetting:GetValue()
    end)

    local tooltipShowAvgSetting = Settings.RegisterAddOnSetting(
        category, "BlazDamage_tooltipShowAvg", "tooltipShowAvg",
        BD.config, Settings.VarType.Boolean, "Tooltip: Average", BD.defaults.tooltipShowAvg
    )
    Settings.CreateCheckbox(category, tooltipShowAvgSetting,
        "Show average damage/healing in tooltips.")
    tooltipShowAvgSetting:SetValueChangedCallback(function()
        BD.config.tooltipShowAvg = tooltipShowAvgSetting:GetValue()
    end)

    local tooltipShowDpsSetting = Settings.RegisterAddOnSetting(
        category, "BlazDamage_tooltipShowDps", "tooltipShowDps",
        BD.config, Settings.VarType.Boolean, "Tooltip: DPS", BD.defaults.tooltipShowDps
    )
    Settings.CreateCheckbox(category, tooltipShowDpsSetting, "Show DPS in tooltips.")
    tooltipShowDpsSetting:SetValueChangedCallback(function()
        BD.config.tooltipShowDps = tooltipShowDpsSetting:GetValue()
    end)

    local tooltipShowDpscSetting = Settings.RegisterAddOnSetting(
        category, "BlazDamage_tooltipShowDpsc", "tooltipShowDpsc",
        BD.config, Settings.VarType.Boolean, "Tooltip: DPS (Cost)", BD.defaults.tooltipShowDpsc
    )
    Settings.CreateCheckbox(category, tooltipShowDpscSetting,
        "Show DPS per resource cost in tooltips.")
    tooltipShowDpscSetting:SetValueChangedCallback(function()
        BD.config.tooltipShowDpsc = tooltipShowDpscSetting:GetValue()
    end)

    local tooltipShowCritSetting = Settings.RegisterAddOnSetting(
        category, "BlazDamage_tooltipShowCrit", "tooltipShowCrit",
        BD.config, Settings.VarType.Boolean, "Tooltip: Crit", BD.defaults.tooltipShowCrit
    )
    Settings.CreateCheckbox(category, tooltipShowCritSetting,
        "Show crit chance % in tooltips.")
    tooltipShowCritSetting:SetValueChangedCallback(function()
        BD.config.tooltipShowCrit = tooltipShowCritSetting:GetValue()
    end)

    local tooltipShowDpmSetting = Settings.RegisterAddOnSetting(
        category, "BlazDamage_tooltipShowDpm", "tooltipShowDpm",
        BD.config, Settings.VarType.Boolean, "Tooltip: Per Resource", BD.defaults.tooltipShowDpm
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
        category, "BlazDamage_discoveryMode", "discoveryMode",
        BD.config, Settings.VarType.String, "Discovery Mode", BD.defaults.discoveryMode
    )
    Settings.CreateDropdown(category, discoveryModeSetting, getDiscoveryOptions,
        "Requires /reload to take effect.")
    discoveryModeSetting:SetValueChangedCallback(function()
        BD.config.discoveryMode = discoveryModeSetting:GetValue()
    end)

    local showPerfSetting = Settings.RegisterAddOnSetting(
        category, "BlazDamage_showPerf", "showPerf",
        BD.config, Settings.VarType.Boolean, "Show Performance Info", BD.defaults.showPerf
    )
    Settings.CreateCheckbox(category, showPerfSetting, "Log performance timing to chat.")
    showPerfSetting:SetValueChangedCallback(function()
        BD.config.showPerf = showPerfSetting:GetValue()
    end)
end

BD.OptionsPanel = OptionsPanel
