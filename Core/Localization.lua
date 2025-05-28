-- AuctionMaster Localization
local addonName, AM = ...

-- Create localization table
AM.L = {}
local L = AM.L

-- Default locale (English)
local locale = {
    -- General
    ["ADDON_NAME"] = "AuctionMaster",
    ["LOADED_MESSAGE"] = "AuctionMaster v%s loaded. Type /am for help.",
    ["SETTINGS"] = "Settings",
    
    -- Time periods
    ["SHORT"] = "Short",
    ["MEDIUM"] = "Medium",
    ["LONG"] = "Long",
    ["VERY_LONG"] = "Very Long",
    ["12_HOURS"] = "12 Hours",
    ["24_HOURS"] = "24 Hours",
    ["48_HOURS"] = "48 Hours",
    ["UNKNOWN"] = "Unknown",
    
    -- Tooltip
    ["MARKET_VALUE"] = "Market Value",
    ["HISTORICAL_VALUE"] = "Historical Value",
    ["MIN_BUYOUT"] = "Minimum Buyout",
    ["VENDOR_SELL_PRICE"] = "Vendor Sell",
    ["PROFIT_VS_VENDOR"] = "Profit vs Vendor",
    ["LAST_SCAN"] = "Last Scan",
    ["NO_PRICE_DATA"] = "No price data available",
    ["TOTAL"] = "total",
    
    -- Scan
    ["SCAN_COMPLETE"] = "Scan complete! Found %d auctions.",
    ["SCANNING_PAGE"] = "Scanning page %d of %d...",
    
    -- Errors
    ["ERROR_AH_CLOSED"] = "Auction House is not open!",
    ["ERROR_SCAN_IN_PROGRESS"] = "A scan is already in progress!",
    ["ERROR_ITEM_NOT_FOUND"] = "Item not found in bags!",
    
    -- Settings
    ["GENERAL_SETTINGS"] = "General",
    ["APPEARANCE_SETTINGS"] = "Appearance",
    ["TOOLTIP_SETTINGS"] = "Tooltips",
    ["SCAN_SETTINGS"] = "Scanning",
    ["POSTING_SETTINGS"] = "Posting",
    ["SHOPPING_SETTINGS"] = "Shopping",
    ["SOUND_SETTINGS"] = "Sound",
    ["DATA_SETTINGS"] = "Data",
    
    ["MINIMAP_BUTTON"] = "Show Minimap Button",
    ["MINIMAP_BUTTON_TOOLTIP"] = "Show or hide the minimap button",
    ["DEBUG_LEVEL"] = "Debug Level",
    ["DEBUG_LEVEL_TOOLTIP"] = "Set the level of debug messages to display",
    ["RESET_SETTINGS"] = "Reset Settings",
    ["RESET_SETTINGS_CONFIRM"] = "Are you sure you want to reset all settings to default?",
    
    ["THEME"] = "Theme",
    ["THEME_TOOLTIP"] = "Choose the visual theme for AuctionMaster",
    ["DEFAULT"] = "Default",
    ["DARK"] = "Dark",
    ["LIGHT"] = "Light",
    ["SCALE"] = "UI Scale",
    ["SCALE_TOOLTIP"] = "Adjust the overall scale of the AuctionMaster UI",
    ["FONT_SCALE"] = "Font Scale",
    ["FONT_SCALE_TOOLTIP"] = "Adjust the scale of text in the AuctionMaster UI",
    
    ["ENABLE_TOOLTIPS"] = "Enable Tooltips",
    ["ENABLE_TOOLTIPS_TOOLTIP"] = "Show AuctionMaster price information in item tooltips",
    ["SHOW_HISTORICAL"] = "Show Historical Prices",
    ["SHOW_HISTORICAL_TOOLTIP"] = "Show historical price data in tooltips",
    ["SHOW_MARKET_VALUE"] = "Show Market Value",
    ["SHOW_MARKET_VALUE_TOOLTIP"] = "Show current market value in tooltips",
    ["SHOW_MIN_BUYOUT"] = "Show Minimum Buyout",
    ["SHOW_MIN_BUYOUT_TOOLTIP"] = "Show minimum buyout price in tooltips",
    ["MODIFIER_KEY"] = "Modifier Key",
    ["MODIFIER_KEY_TOOLTIP"] = "Only show tooltips when this modifier key is held down",
    
    ["AUTO_SCAN"] = "Auto Scan",
    ["AUTO_SCAN_TOOLTIP"] = "Automatically scan the auction house when opened",
    ["SCAN_INTERVAL"] = "Scan Interval (minutes)",
    ["SCAN_INTERVAL_TOOLTIP"] = "Time between automatic scans",
    ["GET_ALL"] = "Use GetAll Scan",
    ["GET_ALL_TOOLTIP"] = "Use the faster GetAll scan method (may disconnect on some servers)",
    ["FAST_SCAN"] = "Fast Scan",
    ["FAST_SCAN_TOOLTIP"] = "Optimize scanning for speed (uses more memory)",
    ["SCAN_THROTTLE"] = "Scan Throttle (ms)",
    ["SCAN_THROTTLE_TOOLTIP"] = "Delay between auction house queries (lower = faster, but may disconnect)",
    
    ["UNDERCUT_AMOUNT"] = "Undercut Amount",
    ["UNDERCUT_AMOUNT_TOOLTIP"] = "Amount to undercut the lowest auction by",
    ["DEFAULT_DURATION"] = "Default Duration",
    ["DEFAULT_DURATION_TOOLTIP"] = "Default auction duration",
    ["DEFAULT_STACK_SIZE"] = "Default Stack Size",
    ["DEFAULT_STACK_SIZE_TOOLTIP"] = "Default stack size for posting",
    ["AUTO_POST"] = "Auto Post",
    ["AUTO_POST_TOOLTIP"] = "Automatically post items when dragged to the auction house",
    
    ["ENABLE_SNIPER"] = "Enable Sniper",
    ["ENABLE_SNIPER_TOOLTIP"] = "Enable the auction sniper to find deals",
    ["SNIPER_INTERVAL"] = "Sniper Interval (seconds)",
    ["SNIPER_INTERVAL_TOOLTIP"] = "Time between sniper scans",
    ["DEAL_NOTIFICATION"] = "Deal Notifications",
    ["DEAL_NOTIFICATION_TOOLTIP"] = "Show notifications when deals are found",
    
    ["ENABLE_ALERTS"] = "Enable Sound Alerts",
    ["ENABLE_ALERTS_TOOLTIP"] = "Play sound alerts for important events",
    ["VOLUME"] = "Alert Volume",
    ["VOLUME_TOOLTIP"] = "Volume level for sound alerts",
    
    ["DATA_RETENTION"] = "Data Retention (days)",
    ["DATA_RETENTION_TOOLTIP"] = "Number of days to keep historical data",
    ["PRUNE_DATA"] = "Prune Old Data",
    ["PRUNE_DATA_CONFIRM"] = "Are you sure you want to prune data older than the retention period?",
    ["DATA_PRUNED"] = "Old data has been pruned.",
    ["RESET_DATABASE"] = "Reset Database",
    ["RESET_DATABASE_CONFIRM"] = "Are you sure you want to reset the entire database? This will delete all scan data and settings!",
    ["DATABASE_RESET"] = "Database has been reset.",
    
    -- Help
    ["HELP_TITLE"] = "AuctionMaster Help",
    ["HELP_COMMANDS"] = "Available commands:",
    ["HELP_SCAN"] = "/am scan - Start a full auction house scan",
    ["HELP_SEARCH"] = "/am search [item] - Search for an item",
    ["HELP_SNIPER"] = "/am sniper - Toggle sniper mode",
    ["HELP_RESET"] = "/am reset - Reset settings to default",
    ["HELP_OPTIONS"] = "/am options - Open the options panel",
    
    -- Sniper
    ["SNIPER_RUNNING"] = "Auction sniper is now running!",
    ["SNIPER_STOPPED"] = "Auction sniper has been stopped.",
    ["DEAL_FOUND"] = "Deal Found",
    
    -- Misc
    ["NONE"] = "None",
    ["ERROR"] = "Error",
    ["WARNING"] = "Warning",
    ["INFO"] = "Info",
    ["VERBOSE"] = "Verbose",
    ["YES"] = "Yes",
    ["NO"] = "No",
    ["SHIFT"] = "Shift",
    ["ALT"] = "Alt",
    ["CTRL"] = "Ctrl",
    ["LEFT_CLICK_TO_OPEN"] = "Left-click to open AuctionMaster",
    ["RIGHT_CLICK_FOR_OPTIONS"] = "Right-click for options",
    ["SETTINGS_RESET"] = "Settings have been reset to default."
}

-- Get localized string
function L:Get(key, ...)
    if not key then return "" end
    
    local str = locale[key]
    if not str then
        return key
    end
    
    if select("#", ...) > 0 then
        return string.format(str, ...)
    else
        return str
    end
end

-- Add localized strings
function L:Add(tbl)
    for k, v in pairs(tbl) do
        locale[k] = v
    end
end
