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
SlashCmdList["BLAZDAMAGE"] = function(msg)
    print("|cFF4FC3F7BlazDamage|r v" .. BD.VERSION)
end
