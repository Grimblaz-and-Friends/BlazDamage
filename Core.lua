local addonName, BD = ...

BD.VERSION = "0.1.0"

-- Addon event handler
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        print("|cFF4FC3F7BlazDamage|r v" .. BD.VERSION .. " loaded.")
    end
end)

-- Slash commands
SLASH_BLAZDAMAGE1 = "/blazdamage"
SLASH_BD1 = "/bd"
SlashCmdList["BLAZDAMAGE"] = function(msg)
    print("|cFF4FC3F7BlazDamage|r v" .. BD.VERSION)
end
