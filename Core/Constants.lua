-- AuctionMaster Core Constants
local addonName, AM = ...

-- Create constants table
AM.Constants = {
    -- Version information
    VERSION = "0.1.0",
    ADDON_NAME = "AuctionMaster",
    
    -- Debug levels
    DEBUG_LEVEL = {
        NONE = 0,
        ERROR = 1,
        WARNING = 2,
        INFO = 3,
        VERBOSE = 4
    },
    
    -- Colors
    COLORS = {
        RED = {r = 1.0, g = 0.1, b = 0.1},
        GREEN = {r = 0.1, g = 1.0, b = 0.1},
        BLUE = {r = 0.1, g = 0.5, b = 1.0},
        YELLOW = {r = 1.0, g = 1.0, b = 0.1},
        ORANGE = {r = 1.0, g = 0.5, b = 0.1},
        PURPLE = {r = 0.8, g = 0.1, b = 0.8},
        GRAY = {r = 0.5, g = 0.5, b = 0.5},
        WHITE = {r = 1.0, g = 1.0, b = 1.0},
        GOLD = {r = 1.0, g = 0.8, b = 0.0}
    },
    
    -- Quality colors
    QUALITY_COLORS = {
        [0] = {r = 0.6, g = 0.6, b = 0.6}, -- Poor (Gray)
        [1] = {r = 1.0, g = 1.0, b = 1.0}, -- Common (White)
        [2] = {r = 0.2, g = 1.0, b = 0.2}, -- Uncommon (Green)
        [3] = {r = 0.2, g = 0.6, b = 1.0}, -- Rare (Blue)
        [4] = {r = 0.8, g = 0.3, b = 1.0}, -- Epic (Purple)
        [5] = {r = 1.0, g = 0.5, b = 0.0}, -- Legendary (Orange)
        [6] = {r = 1.0, g = 0.0, b = 0.0}, -- Artifact (Red)
        [7] = {r = 0.9, g = 0.8, b = 0.5}  -- Heirloom (Gold)
    },
    
    -- Scan types
    SCAN_TYPE_FULL = 1,
    SCAN_TYPE_TARGETED = 2,
    SCAN_TYPE_SNIPER = 3,
    
    -- Price types
    PRICE_TYPE_MARKET = 1,
    PRICE_TYPE_HISTORICAL = 2,
    PRICE_TYPE_MINIMUM = 3,
    PRICE_TYPE_MAXIMUM = 4,
    PRICE_TYPE_RECENT = 5,
    
    -- Time periods
    TIME_PERIOD_DAILY = 1,
    TIME_PERIOD_WEEKLY = 2,
    TIME_PERIOD_MONTHLY = 3,
    
    -- Auction durations
    AUCTION_DURATION_12 = 1,
    AUCTION_DURATION_24 = 2,
    AUCTION_DURATION_48 = 3,
    
    -- Custom events
    EVENTS = {
        SCAN_START = "AUCTIONMASTER_SCAN_START",
        SCAN_PROGRESS = "AUCTIONMASTER_SCAN_PROGRESS",
        SCAN_COMPLETE = "AUCTIONMASTER_SCAN_COMPLETE",
        SCAN_FAILED = "AUCTIONMASTER_SCAN_FAILED",
        PRICE_UPDATE = "AUCTIONMASTER_PRICE_UPDATE",
        DEAL_FOUND = "AUCTIONMASTER_DEAL_FOUND",
        OWNED_AUCTIONS_UPDATED = "AUCTIONMASTER_OWNED_AUCTIONS_UPDATED"
    },
    
    -- Default settings
    DEFAULT_SETTINGS = {
        general = {
            minimap = {
                hide = false,
                minimapPos = 220,
                radius = 80,
            },
            debugLevel = 1, -- ERROR
            dataRetention = 30, -- days
        },
        appearance = {
            theme = "default",
            scale = 1.0,
            fontScale = 1.0,
        },
        tooltips = {
            enable = true,
            showMarketValue = true,
            showHistorical = true,
            showMinBuyout = true,
            showNoData = true,
            modifierKey = "none", -- none, shift, alt, ctrl
        },
        scanning = {
            autoScan = false,
            scanInterval = 60, -- minutes
            getAll = false,
            fastScan = true,
            scanThrottle = 100, -- ms
        },
        posting = {
            undercut = 1,
            defaultDuration = 2, -- 1=12h, 2=24h, 3=48h
            defaultStackSize = 1,
            autoPost = false,
            fixedPricePercentage = 100,
        },
        shopping = {
            enableSniper = false,
            sniperInterval = 2.5, -- seconds
            dealNotification = true,
        },
        sound = {
            enableAlerts = true,
            volume = 0.5,
        },
    }
}
