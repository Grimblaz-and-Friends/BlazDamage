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
        category, "Overlay Metric", "metric",
        BD.config, Settings.VarType.String, BD.defaults.metric
    )
    Settings.CreateDropdown(category, metricSetting, getMetricOptions,
        "Which metric to display on action bar buttons.")
    metricSetting:SetValueChangedCallback(function()
        if BD.OverlayRenderer then BD.OverlayRenderer.refreshAll() end
    end)

    local showOverlaysSetting = Settings.RegisterAddOnSetting(
        category, "Show Overlays", "showOverlays",
        BD.config, Settings.VarType.Boolean, BD.defaults.showOverlays
    )
    Settings.CreateCheckbox(category, showOverlaysSetting,
        "Show damage/healing metrics on action bar buttons.")
    showOverlaysSetting:SetValueChangedCallback(function()
        if BD.OverlayRenderer then BD.OverlayRenderer.refreshAll() end
    end)

    local fontSizeSetting = Settings.RegisterAddOnSetting(
        category, "Overlay Font Size", "overlayFontSize",
        BD.config, Settings.VarType.Number, BD.defaults.overlayFontSize
    )
    local sliderOptions = Settings.CreateSliderOptions(8, 20, 1)
    sliderOptions:SetFormat("%d")
    Settings.CreateSlider(category, fontSizeSetting, sliderOptions, "Font size for overlay text.")
    fontSizeSetting:SetValueChangedCallback(function()
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
        category, "Overlay Position", "overlayPosition",
        BD.config, Settings.VarType.String, BD.defaults.overlayPosition
    )
    Settings.CreateDropdown(category, positionSetting, getPositionOptions,
        "Where to anchor the overlay text on each button.")
    positionSetting:SetValueChangedCallback(function()
        if BD.OverlayRenderer and BD.OverlayRenderer.applyStyle then
            BD.OverlayRenderer.applyStyle()
        end
    end)

    -- [TOOLTIP SECTION]
    local showTooltipsSetting = Settings.RegisterAddOnSetting(
        category, "Show Tooltips", "showTooltips",
        BD.config, Settings.VarType.Boolean, BD.defaults.showTooltips
    )
    Settings.CreateCheckbox(category, showTooltipsSetting,
        "Show damage/healing metrics in spell tooltips.")

    local tooltipShowAvgSetting = Settings.RegisterAddOnSetting(
        category, "Tooltip: Average", "tooltipShowAvg",
        BD.config, Settings.VarType.Boolean, BD.defaults.tooltipShowAvg
    )
    Settings.CreateCheckbox(category, tooltipShowAvgSetting,
        "Show average damage/healing in tooltips.")

    local tooltipShowDpsSetting = Settings.RegisterAddOnSetting(
        category, "Tooltip: DPS", "tooltipShowDps",
        BD.config, Settings.VarType.Boolean, BD.defaults.tooltipShowDps
    )
    Settings.CreateCheckbox(category, tooltipShowDpsSetting, "Show DPS in tooltips.")

    local tooltipShowDpscSetting = Settings.RegisterAddOnSetting(
        category, "Tooltip: DPS (Cost)", "tooltipShowDpsc",
        BD.config, Settings.VarType.Boolean, BD.defaults.tooltipShowDpsc
    )
    Settings.CreateCheckbox(category, tooltipShowDpscSetting,
        "Show DPS per resource cost in tooltips.")

    local tooltipShowCritSetting = Settings.RegisterAddOnSetting(
        category, "Tooltip: Crit", "tooltipShowCrit",
        BD.config, Settings.VarType.Boolean, BD.defaults.tooltipShowCrit
    )
    Settings.CreateCheckbox(category, tooltipShowCritSetting,
        "Show crit chance % in tooltips.")

    local tooltipShowDpmSetting = Settings.RegisterAddOnSetting(
        category, "Tooltip: DPM", "tooltipShowDpm",
        BD.config, Settings.VarType.Boolean, BD.defaults.tooltipShowDpm
    )
    Settings.CreateCheckbox(category, tooltipShowDpmSetting, "Show damage per mana in tooltips.")

    -- [MISC SECTION]
    local function getDiscoveryOptions()
        local container = Settings.CreateControlTextContainer()
        container:Add("auto", "Auto")
        container:Add("update", "Update Hook")
        return container:GetData()
    end
    local discoveryModeSetting = Settings.RegisterAddOnSetting(
        category, "Discovery Mode", "discoveryMode",
        BD.config, Settings.VarType.String, BD.defaults.discoveryMode
    )
    Settings.CreateDropdown(category, discoveryModeSetting, getDiscoveryOptions,
        "Requires /reload to take effect.")

    local showPerfSetting = Settings.RegisterAddOnSetting(
        category, "Show Performance Info", "showPerf",
        BD.config, Settings.VarType.Boolean, BD.defaults.showPerf
    )
    Settings.CreateCheckbox(category, showPerfSetting, "Log performance timing to chat.")
end

BD.OptionsPanel = OptionsPanel
