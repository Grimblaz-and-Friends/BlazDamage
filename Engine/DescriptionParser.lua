-- Engine/DescriptionParser.lua
-- Pure Lua 5.1 — zero WoW API calls. Testable with busted.

local DescriptionParser = {}

-- Dual-load support: works via require() in busted AND via BD namespace in WoW.
local _, BD = ...
if type(BD) ~= "table" then BD = {} end -- luacheck: ignore 331

-- Pattern table — edit here to add locale variants or new spell formats.
local PATTERNS = {
    strip_color   = "|c%x%x%x%x%x%x%x%x(.-)%|r",
    strip_texture = "|T.-|t",
    channel       = "[Cc]hannels? ([%d,]+)[%a%s]*damage over (%d+) sec",
    range_dot     = "([%d,]+) to ([%d,]+)[%a%s]*damage over (%d+) sec",
    dot           = "([%d,]+)[%a%s]*damage over (%d+) sec",
    range         = "([%d,]+) to ([%d,]+)[%a%s]*damage",
    direct        = "([%d,]+)[%a%s]*damage",
    range_heal    = "[Hh]eals?.- for ([%d,]+) to ([%d,]+)",
    heal          = "[Hh]eals?.- for ([%d,]+)",
    range_restore = "[Rr]estore[sd]?.- ([%d,]+) to ([%d,]+).- health",
    restore       = "[Rr]estore[sd]?.- ([%d,]+).- health",
}

local function stripMarkup(text)
    text = text:gsub(PATTERNS.strip_color, "%1")
    text = text:gsub(PATTERNS.strip_texture, "")
    return text
end

local function parseNumber(str)
    return tonumber((str:gsub(",", "")))
end

local function singleComponent(rawDmg, compType, duration)
    local n = parseNumber(rawDmg)
    return { min = n, max = n, type = compType, duration = duration }
end

local function rangeComponent(lo, hi, compType, duration)
    return { min = parseNumber(lo), max = parseNumber(hi), type = compType, duration = duration }
end

local function parseSegment(text)
    -- Channel: "Channels N damage over D sec"
    local dmg, dur = text:match(PATTERNS.channel)
    if dmg then return singleComponent(dmg, "channel", tonumber(dur)) end

    -- Range damage over time: "N to M <school> damage over D sec"
    local minDmg, maxDmg, dur2 = text:match(PATTERNS.range_dot)
    if minDmg then return rangeComponent(minDmg, maxDmg, "dot", tonumber(dur2)) end

    -- Damage over time: "N <school> damage over D sec"
    dmg, dur = text:match(PATTERNS.dot)
    if dmg then return singleComponent(dmg, "dot", tonumber(dur)) end

    -- Range direct: "N to M damage"
    local lo, hi = text:match(PATTERNS.range)
    if lo then return rangeComponent(lo, hi, "direct") end

    -- Single direct: "N <optional school> damage"
    dmg = text:match(PATTERNS.direct)
    if dmg then return singleComponent(dmg, "direct") end

    -- Range heal: "Heals for N to M"  (must check before single heal)
    lo, hi = text:match(PATTERNS.range_heal)
    if lo then return rangeComponent(lo, hi, "heal") end

    -- Heal: "Heals for N"  (.- matches intermediate digits, e.g. "within 40 yards for N")
    dmg = text:match(PATTERNS.heal)
    if dmg then return singleComponent(dmg, "heal") end

    -- Range restore: "Restores N to M of...health"  (must check before single restore)
    lo, hi = text:match(PATTERNS.range_restore)
    if lo then return rangeComponent(lo, hi, "heal") end

    -- Restore: "Restores N of...health"
    dmg = text:match(PATTERNS.restore)
    if dmg then return singleComponent(dmg, "heal") end

    return nil
end

function DescriptionParser.parse(description)
    if description == nil or description == "" then
        return nil
    end

    local text = stripMarkup(description)

    if text:match("^%s*$") then
        return nil
    end

    -- Split on ", then " to handle mixed direct+DoT descriptions.
    local segments = {}
    local remaining = text
    while true do
        local splitAt = remaining:find(", then ", 1, true)
        if splitAt then
            table.insert(segments, remaining:sub(1, splitAt - 1))
            remaining = remaining:sub(splitAt + 7)
        else
            table.insert(segments, remaining)
            break
        end
    end

    local components = {}
    for _, segment in ipairs(segments) do
        local component = parseSegment(segment)
        -- Skip components where parseNumber() returned nil (e.g. commas-only capture).
        if component and type(component.min) == "number" and type(component.max) == "number" then
            table.insert(components, component)
        end
    end

    if #components == 0 then
        return nil
    end

    return components
end

BD.DescriptionParser = DescriptionParser
return DescriptionParser
