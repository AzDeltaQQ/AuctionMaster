# AuctionMaster: Database Structure

This document outlines the database structure for AuctionMaster, detailing how auction data, settings, and other information will be stored and managed.

## SavedVariables Structure

AuctionMaster will use the following SavedVariables structure:

```lua
AuctionMasterDB = {
    -- Global settings shared across all characters
    global = {
        version = "1.0.0",
        settings = {
            -- Global addon settings
            general = {
                minimap = { hide = false, position = 45 },
                debug = false,
                dataRetention = 30, -- days
                scanThrottle = 100, -- ms
            },
            appearance = {
                theme = "default",
                scale = 1.0,
                fontScale = 1.0,
            },
            tooltips = {
                enable = true,
                showHistorical = true,
                showMarketValue = true,
                showMinBuyout = true,
                modifierKey = "none", -- "shift", "alt", "ctrl", "none"
            },
            sound = {
                enableAlerts = true,
                volume = 0.5,
            },
        },
        -- Shared price data (optional, can be disabled)
        sharedData = {
            lastUpdated = 0,
            serverPrices = {},
        },
    },
    
    -- Per-character settings and data
    char = {
        ["CharacterName-Realm"] = {
            settings = {
                -- Character-specific overrides
                general = {},
                scanning = {},
                posting = {},
                shopping = {},
            },
            
            -- UI state
            ui = {
                framePositions = {},
                columnWidths = {},
                lastTab = "browse",
            },
            
            -- Shopping lists
            shopping = {
                lists = {
                    -- List name to items mapping
                    ["Default"] = {
                        items = {
                            -- [itemID] = {maxPrice = 1000, notes = "For crafting"}
                        },
                        lastSearch = 0,
                    },
                },
                history = {
                    -- Purchase history
                    -- [timestamp] = {itemID, quantity, price, seller}
                },
            },
            
            -- Posting profiles
            posting = {
                profiles = {
                    ["Default"] = {
                        undercut = 1,
                        duration = 2, -- 1=12h, 2=24h, 3=48h
                        stackSize = 1,
                        autoPost = false,
                    },
                },
                itemSettings = {
                    -- [itemID] = {profileName = "Default", minPrice = 100, maxPrice = 1000}
                },
                history = {
                    -- [timestamp] = {itemID, quantity, price, duration}
                },
            },
        },
    },
    
    -- Realm-specific data
    realm = {
        ["RealmName"] = {
            lastScan = 0,
            scanStats = {
                totalScans = 0,
                lastFullScan = 0,
                averageScanTime = 0,
            },
            
            -- Current auction data
            auctions = {
                -- [itemKey] = {
                --     minBid = 0,
                --     minBuyout = 0,
                --     quantity = 0,
                --     owners = {"Seller1", "Seller2"},
                --     lastSeen = 0,
                -- }
            },
            
            -- Historical price data
            history = {
                -- [itemKey] = {
                --     daily = {
                --         [timestamp] = {minBuyout = 0, avgBuyout = 0, quantity = 0}
                --     },
                --     weekly = {
                --         [weekTimestamp] = {minBuyout = 0, avgBuyout = 0, quantity = 0}
                --     },
                --     monthly = {
                --         [monthTimestamp] = {minBuyout = 0, avgBuyout = 0, quantity = 0}
                --     }
                -- }
            },
            
            -- Market statistics
            marketStats = {
                -- [itemKey] = {
                --     marketValue = 0,
                --     historicalValue = 0,
                --     minPrice = 0,
                --     maxPrice = 0,
                --     stdDev = 0,
                --     soldPerDay = 0,
                --     lastUpdated = 0,
                -- }
            },
            
            -- Item information cache
            itemCache = {
                -- [itemID] = {
                --     name = "Item Name",
                --     link = "|cff1eff00|Hitem:12345:0:0:0:0:0:0:0:0|h[Item Name]|h|r",
                --     quality = 2,
                --     level = 70,
                --     class = "Weapon",
                --     subclass = "Sword",
                --     vendorSell = 100,
                --     lastUpdated = 0,
                -- }
            },
        },
    },
}
```

## Item Key Format

To efficiently identify items, AuctionMaster will use a composite item key format that accounts for variations:

```lua
-- Format: itemID:suffix:enchant:gem1:gem2:gem3
-- Example: "12345:0:0:0:0:0" for a basic item
-- Example: "12345:15:0:0:0:0" for an item with a suffix
```

This format allows for proper differentiation between item variations while maintaining compatibility with the WoW 3.3.5a item system.

## Data Compression

For large datasets, AuctionMaster will employ LibCompress to reduce the size of SavedVariables:

1. Historical data will be compressed when it reaches a configurable threshold
2. Compressed data will be stored in a binary format and decompressed on demand
3. Rarely accessed data will remain compressed to save memory

## Data Pruning

To maintain reasonable SavedVariables size and memory usage:

1. Historical data older than the configured retention period will be automatically pruned
2. Aggregation will be used for older data (daily → weekly → monthly)
3. Items not seen for extended periods will have their detailed history removed, keeping only summary statistics
4. Users can manually trigger data pruning for specific item categories

## Database Access Layer

The database will be accessed through a dedicated API layer:

```lua
-- Example API functions
AuctionMaster.DB = {
    GetItemPrice = function(itemID, priceType)
        -- Returns requested price for an item
    end,
    
    SaveAuctionData = function(itemID, data)
        -- Stores auction data and updates statistics
    end,
    
    GetSetting = function(path, default)
        -- Retrieves a setting with character-specific override support
    end,
    
    SetSetting = function(path, value)
        -- Updates a setting
    end,
    
    PruneData = function(olderThan, itemClass)
        -- Removes old data matching criteria
    end,
    
    ExportData = function(format, selection)
        -- Exports data in specified format
    end,
    
    ImportData = function(data, merge)
        -- Imports data with optional merging
    end,
}
```

## Performance Optimizations

The database structure includes several optimizations:

1. Lazy loading of data components to reduce initial memory footprint
2. Caching of frequently accessed data
3. Batch processing for database updates
4. Throttled writes to prevent UI freezes
5. Incremental updates to avoid full database reloads
6. Efficient indexing for common query patterns

This database structure provides a solid foundation for storing and managing all the data required by AuctionMaster's features while maintaining performance and efficiency.
