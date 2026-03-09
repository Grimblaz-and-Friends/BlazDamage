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
    range         = "([%d,]+) to ([%d,]+) damage",
    direct        = "([%d,]+)[%a%s]*damage",
    heal          = "[Hh]eals? for ([%d,]+)",
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

local function parseSegment(text)
    -- Channel: "Channels N damage over D sec"
    local dmg, dur = text:match(PATTERNS.channel)
    if dmg then return singleComponent(dmg, "channel", tonumber(dur)) end

    -- Range damage over time: "N to M <school> damage over D sec"
    local minDmg, maxDmg, dur2 = text:match(PATTERNS.range_dot)
    if minDmg then
        return { min = parseNumber(minDmg), max = parseNumber(maxDmg), type = "dot", duration = tonumber(dur2) }
    end

    -- Damage over time: "N <school> damage over D sec"
    dmg, dur = text:match(PATTERNS.dot)
    if dmg then return singleComponent(dmg, "dot", tonumber(dur)) end

    -- Range direct: "N to M damage"
    local lo, hi = text:match(PATTERNS.range)
    if lo then
        return { min = parseNumber(lo), max = parseNumber(hi), type = "direct" }
    end

    -- Single direct: "N <optional school> damage"
    dmg = text:match(PATTERNS.direct)
    if dmg then return singleComponent(dmg, "direct") end

    -- Heal: "Heals for N"
    dmg = text:match(PATTERNS.heal)
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
        if component then
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
