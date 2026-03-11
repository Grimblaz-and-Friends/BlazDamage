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
        print("|cFF4FC3F7BlazDamage|r v" .. BD.VERSION .. " loaded.")
    end
end)

-- Slash commands
SLASH_BLAZDAMAGE1 = "/blazdamage"
SLASH_BLAZDAMAGE2 = "/bd"
local PREFIX = "|cFFFFFF00BlazDamage:|r"
SlashCmdList["BLAZDAMAGE"] = function(msg)
    if msg == "" or msg == nil then
        print(PREFIX .. " v" .. BD.VERSION)
    elseif msg == "discovery" then
        local mode = BD.config and BD.config.discoveryMode or BD.defaults.discoveryMode
        print(PREFIX .. " Discovery mode: " .. tostring(mode))
    elseif msg == "discovery auto" or msg == "discovery update" then
        local mode = (msg == "discovery auto") and "auto" or "update"
        if BD.config then BD.config.discoveryMode = mode end
        print(PREFIX .. " Discovery mode set to: " .. mode .. " (reload to apply)")
    else
        print(PREFIX .. " Unknown command: " .. tostring(msg))
    end
end
