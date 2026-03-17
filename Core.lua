local addonName, BD = ...

BD.VERSION = "0.1.0"

-- Addon event handler
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        if type(BlazDamageDB) ~= "table" then
            BlazDamageDB = {}
        end
        -- Merge defaults into saved vars (nil-fill: only fills missing keys, one level)
        for k, v in pairs(BD.defaults) do
            if BlazDamageDB[k] == nil then
                BlazDamageDB[k] = v
            end
        end
        BD.config = BlazDamageDB
        if BD.OptionsPanel then BD.OptionsPanel.init() end
        print("|cFF4FC3F7BlazDamage|r v" .. BD.VERSION .. " loaded.")
    end
end)

-- Slash commands
SLASH_BLAZDAMAGE1 = "/blazdamage"
SLASH_BLAZDAMAGE2 = "/bd"
local PREFIX = BD.PREFIX
local function openOptionsPanel()
    if BD.optionsCategoryID then
        Settings.OpenToCategory(BD.optionsCategoryID)
    else
        print(PREFIX .. " Options panel not available.")
    end
end
SlashCmdList["BLAZDAMAGE"] = function(msg)
    msg = (msg or ""):lower()
    local validMetrics = table.concat(BD.VALID_METRICS, ", ")

    if msg == "" then
        if not BD.config then print(PREFIX .. " Not ready yet.") return end
        openOptionsPanel()
        return
    end

    local cmd, arg = string.match(msg, "^(%S+)%s*(.-)%s*$")
    if not cmd then return end

    if cmd ~= "help" and not BD.config then
        print(PREFIX .. " Not ready yet.")
        return
    end

    if cmd == "metric" then
        if arg == "" then
            print(PREFIX .. " Metric: " .. BD.config.metric)
            print(PREFIX .. " Valid metrics: " .. validMetrics)
            return
        end
        local valid = false
        for _, v in ipairs(BD.VALID_METRICS) do
            if v == arg then valid = true; break end
        end
        if not valid then
            print(PREFIX .. " Invalid metric: " .. arg)
            print(PREFIX .. " Valid metrics: " .. validMetrics)
            return
        end
        BD.config.metric = arg
        if BD.OverlayRenderer then BD.OverlayRenderer.refreshAll() end
        print(PREFIX .. " Metric set to: " .. arg)

    elseif cmd == "overlay" then
        BD.config.showOverlays = not BD.config.showOverlays
        if BD.OverlayRenderer then BD.OverlayRenderer.refreshAll() end
        print(PREFIX .. " Overlays: " .. (BD.config.showOverlays and "Enabled" or "Disabled"))

    elseif cmd == "tooltip" then
        BD.config.showTooltips = not BD.config.showTooltips
        print(PREFIX .. " Tooltips: " .. (BD.config.showTooltips and "Enabled" or "Disabled"))

    elseif cmd == "perf" then
        BD.config.showPerf = not BD.config.showPerf
        print(PREFIX .. " Perf: " .. (BD.config.showPerf and "Enabled" or "Disabled"))

    elseif cmd == "discovery" then
        if arg == "" then
            print(PREFIX .. " Discovery mode: " .. BD.config.discoveryMode)
        elseif arg == "auto" or arg == "update" then
            BD.config.discoveryMode = arg
            print(PREFIX .. " Discovery mode set to: " .. arg .. " (reload to apply)")
        else
            print(PREFIX .. " Unknown discovery mode: " .. arg .. ". Valid: auto, update")
        end

    elseif cmd == "options" then
        openOptionsPanel()

    elseif cmd == "status" then
        print(PREFIX .. " v" .. BD.VERSION)
        print(PREFIX .. "  Metric:     " .. BD.config.metric)
        print(PREFIX .. "  Overlays:   " .. (BD.config.showOverlays and "Enabled" or "Disabled"))
        print(PREFIX .. "  Tooltips:   " .. (BD.config.showTooltips and "Enabled" or "Disabled"))
        print(PREFIX .. "  Font Size:  " .. BD.config.overlayFontSize)
        print(PREFIX .. "  Position:   " .. BD.config.overlayPosition)
        print(PREFIX .. "  Tip Avg:    " .. (BD.config.tooltipShowAvg ~= false and "Enabled" or "Disabled"))
        print(PREFIX .. "  Tip DPS:    " .. (BD.config.tooltipShowDps ~= false and "Enabled" or "Disabled"))
        print(PREFIX .. "  Tip DPSC:   " .. (BD.config.tooltipShowDpsc ~= false and "Enabled" or "Disabled"))
        print(PREFIX .. "  Tip Crit:   " .. (BD.config.tooltipShowCrit ~= false and "Enabled" or "Disabled"))
        print(PREFIX .. "  Tip DPM:    " .. (BD.config.tooltipShowDpm ~= false and "Enabled" or "Disabled"))
        print(PREFIX .. "  Discovery:  " .. BD.config.discoveryMode)
        print(PREFIX .. "  Perf:       " .. (BD.config.showPerf and "Enabled" or "Disabled"))

    elseif cmd == "help" then
        print(PREFIX .. " Commands:")
        print(PREFIX .. "  /bd                         — open options panel")
        print(PREFIX .. "  /bd options                 — open options panel")
        print(PREFIX .. "  /bd status                  — show all settings")
        print(PREFIX .. "  /bd metric <name>           — set overlay metric (" .. validMetrics .. ")")
        print(PREFIX .. "  /bd overlay                 — toggle overlays")
        print(PREFIX .. "  /bd tooltip                 — toggle tooltips")
        print(PREFIX .. "  /bd perf                    — toggle performance logging")
        print(PREFIX .. "  /bd discovery [auto|update] — show/set discovery mode")
        print(PREFIX .. "  /bd help                    — show this help")

    else
        print(PREFIX .. " Unknown command: " .. cmd .. ". Type /bd help for commands.")
    end
end
