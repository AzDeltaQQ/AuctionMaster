-- AuctionMaster Utilities
local addonName, AM = ...
local L = AM.L

AM.Util = {}

-- Format money values into a readable string
function AM.Util.FormatMoney(copper, colorize)
    if not copper then return "0g" end
    
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copper = copper % 100
    
    local text = ""
    
    if gold > 0 then
        if colorize then
            text = text .. "|cFFFFD700" .. gold .. "g|r"
        else
            text = text .. gold .. "g"
        end
    end
    
    if silver > 0 or (gold > 0 and copper > 0) then
        if colorize then
            text = text .. "|cFFC0C0C0" .. silver .. "s|r"
        else
            text = text .. silver .. "s"
        end
    end
    
    if copper > 0 or (gold == 0 and silver == 0) then
        if colorize then
            text = text .. "|cFFB87333" .. copper .. "c|r"
        else
            text = text .. copper .. "c"
        end
    end
    
    return text
end

-- Convert a string money value to copper
function AM.Util.ParseMoney(text)
    if not text or text == "" then return 0 end
    
    local gold = tonumber(string.match(text, "(%d+)g")) or 0
    local silver = tonumber(string.match(text, "(%d+)s")) or 0
    local copper = tonumber(string.match(text, "(%d+)c")) or 0
    
    return gold * 10000 + silver * 100 + copper
end

-- Format a number with commas
function AM.Util.FormatNumber(number)
    if not number then return "0" end
    
    local formatted = tostring(number)
    local k
    
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    
    return formatted
end

-- Get item key from item link or ID
function AM.Util.GetItemKey(itemLink)
    if not itemLink then return nil end
    
    local itemID, itemString
    
    if type(itemLink) == "number" then
        itemID = itemLink
        itemString = "item:" .. itemID .. ":0:0:0:0:0:0:0"
    else
        itemString = string.match(itemLink, "(item:[^|]+)")
        if not itemString then return nil end
        
        itemID = tonumber(string.match(itemString, "item:(%d+)"))
        if not itemID then return nil end
    end
    
    -- Extract suffix and enchant info
    local _, _, enchant, suffix = string.find(itemString, "item:%d+:(%d*):(%d*)")
    enchant = tonumber(enchant) or 0
    suffix = tonumber(suffix) or 0
    
    -- Create a standardized item key
    local itemKey = itemID .. ":" .. suffix .. ":" .. enchant
    
    return itemKey
end

-- Get item info from cache or game API
function AM.Util.GetItemInfo(itemLink)
    if not itemLink then return nil end
    
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, 
          itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemLink)
    
    if not itemName then return nil end
    
    return {
        name = itemName,
        link = itemLink,
        quality = itemQuality,
        level = itemLevel,
        minLevel = itemMinLevel,
        type = itemType,
        subType = itemSubType,
        stackCount = itemStackCount,
        equipLoc = itemEquipLoc,
        texture = itemTexture
    }
end

-- Get time left text from auction time left code
function AM.Util.GetTimeLeftText(timeLeft)
    if timeLeft == 1 then
        return L:Get("SHORT"), AM.Constants.COLORS.RED
    elseif timeLeft == 2 then
        return L:Get("MEDIUM"), AM.Constants.COLORS.ORANGE
    elseif timeLeft == 3 then
        return L:Get("LONG"), AM.Constants.COLORS.GOLD
    else
        return L:Get("VERY_LONG"), AM.Constants.COLORS.GREEN
    end
end

-- Get duration text from auction duration code
function AM.Util.GetDurationText(duration)
    if duration == AM.Constants.AUCTION_DURATION_12 then
        return L:Get("12_HOURS")
    elseif duration == AM.Constants.AUCTION_DURATION_24 then
        return L:Get("24_HOURS")
    elseif duration == AM.Constants.AUCTION_DURATION_48 then
        return L:Get("48_HOURS")
    else
        return L:Get("UNKNOWN")
    end
end

-- Get colored text based on item quality
function AM.Util.GetQualityColoredText(text, quality)
    if not quality or not AM.Constants.QUALITY_COLORS[quality] then
        return text
    end
    
    local color = AM.Constants.QUALITY_COLORS[quality]
    local hexColor = string.format("%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
    
    return "|cFF" .. hexColor .. text .. "|r"
end

-- Debug logging function
function AM.Util.Debug(level, ...)
    if not AM.db or not AM.db.global or not AM.db.global.settings then return end
    
    local debugLevel = AM.db.global.settings.general.debugLevel or AM.Constants.DEBUG_LEVEL.ERROR
    
    if level <= debugLevel then
        local prefix = "|cFF00CCFF[AuctionMaster]|r "
        local msg = string.format(...)
        
        if level == AM.Constants.DEBUG_LEVEL.ERROR then
            prefix = "|cFFFF0000[AuctionMaster ERROR]|r "
        elseif level == AM.Constants.DEBUG_LEVEL.WARNING then
            prefix = "|cFFFFCC00[AuctionMaster WARNING]|r "
        end
        
        print(prefix .. msg)
    end
end

-- Round a number to specified decimal places
function AM.Util.Round(num, places)
    if not places then places = 0 end
    local mult = 10^places
    return math.floor(num * mult + 0.5) / mult
end

-- Deep copy a table
function AM.Util.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[AM.Util.DeepCopy(orig_key)] = AM.Util.DeepCopy(orig_value)
        end
        setmetatable(copy, AM.Util.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Merge two tables, with second table taking precedence
function AM.Util.MergeTables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k] or false) == "table" then
            AM.Util.MergeTables(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end

-- Get current realm name
function AM.Util.GetRealmName()
    local realm = GetRealmName()
    return realm
end

-- Get current character name with realm
function AM.Util.GetCharacterName()
    local name = UnitName("player")
    local realm = AM.Util.GetRealmName()
    return name .. "-" .. realm
end

-- Get current timestamp
function AM.Util.GetCurrentTimestamp()
    return time()
end

-- Format timestamp to date string
function AM.Util.FormatTimestamp(timestamp)
    if not timestamp then return "Unknown" end
    
    local date = date("*t", timestamp)
    return string.format("%d/%d/%d %d:%02d", 
        date.month, date.day, date.year, date.hour, date.min)
end

-- Calculate time difference in a human-readable format
function AM.Util.GetTimeDifference(timestamp)
    if not timestamp then return "Unknown" end
    
    local diff = time() - timestamp
    
    if diff < 60 then
        return diff .. " " .. (diff == 1 and "second" or "seconds") .. " ago"
    elseif diff < 3600 then
        local mins = math.floor(diff / 60)
        return mins .. " " .. (mins == 1 and "minute" or "minutes") .. " ago"
    elseif diff < 86400 then
        local hours = math.floor(diff / 3600)
        return hours .. " " .. (hours == 1 and "hour" or "hours") .. " ago"
    elseif diff < 604800 then
        local days = math.floor(diff / 86400)
        return days .. " " .. (days == 1 and "day" or "days") .. " ago"
    elseif diff < 2592000 then
        local weeks = math.floor(diff / 604800)
        return weeks .. " " .. (weeks == 1 and "week" or "weeks") .. " ago"
    else
        local months = math.floor(diff / 2592000)
        return months .. " " .. (months == 1 and "month" or "months") .. " ago"
    end
end
