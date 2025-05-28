-- AuctionMaster Database
local addonName, AM = ...
local L = AM.L

-- Initialize the database module
AM.DB = {}

-- Default database structure
local defaultDB = {
    -- Global settings shared across all characters
    global = {
        version = AM.Constants.VERSION,
        settings = AM.Constants.DEFAULT_SETTINGS,
        -- Shared price data (optional, can be disabled)
        sharedData = {
            lastUpdated = 0,
            serverPrices = {},
        },
    },
    
    -- Per-character settings and data
    char = {},
    
    -- Realm-specific data
    realm = {},
}

-- Initialize the database
function AM.DB:Initialize()
    -- Create the saved variable if it doesn't exist
    if not AuctionMasterDB then
        AuctionMasterDB = {}
    end
    
    -- Ensure the database has the correct structure
    if not AuctionMasterDB.global then
        AuctionMasterDB.global = defaultDB.global
    end
    
    if not AuctionMasterDB.char then
        AuctionMasterDB.char = {}
    end
    
    if not AuctionMasterDB.realm then
        AuctionMasterDB.realm = {}
    end
    
    -- Get character name
    local charName = AM.Util.GetCharacterName()
    
    -- Initialize character data if needed
    if not AuctionMasterDB.char[charName] then
        AuctionMasterDB.char[charName] = {
            settings = {},
            ui = {
                framePositions = {},
                columnWidths = {},
                lastTab = "browse",
            },
            shopping = {
                lists = {
                    ["Default"] = {
                        items = {},
                        lastSearch = 0,
                    },
                },
                history = {},
            },
            posting = {
                profiles = {
                    ["Default"] = {
                        undercut = 1,
                        duration = 2, -- 1=12h, 2=24h, 3=48h
                        stackSize = 1,
                        autoPost = false,
                    },
                },
                itemSettings = {},
                history = {},
            },
        }
    end
    
    -- Get realm name
    local realmName = AM.Util.GetRealmName()
    
    -- Initialize realm data if needed
    if not AuctionMasterDB.realm[realmName] then
        AuctionMasterDB.realm[realmName] = {
            lastScan = 0,
            scanStats = {
                totalScans = 0,
                lastFullScan = 0,
                averageScanTime = 0,
            },
            auctions = {},
            history = {},
            marketStats = {},
            itemCache = {},
        }
    end
    
    -- Store references for easier access
    self.db = AuctionMasterDB
    self.global = self.db.global
    self.char = self.db.char[charName]
    self.realm = self.db.realm[realmName]
    
    -- Update version if needed
    if self.global.version ~= AM.Constants.VERSION then
        self:UpgradeDatabase(self.global.version)
        self.global.version = AM.Constants.VERSION
    end
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Database initialized")
end

-- Upgrade database from previous versions
function AM.DB:UpgradeDatabase(oldVersion)
    -- Handle version upgrades here
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Database upgraded from version %s to %s", oldVersion, AM.Constants.VERSION)
end

-- Get a setting value with character-specific override support
function AM.DB:GetSetting(path, default)
    local parts = {strsplit(".", path)}
    local category = parts[1]
    local setting = parts[2]
    
    if not category or not setting then
        return default
    end
    
    -- Check for character-specific override
    if self.char.settings[category] and self.char.settings[category][setting] ~= nil then
        return self.char.settings[category][setting]
    end
    
    -- Fall back to global setting
    if self.global.settings[category] and self.global.settings[category][setting] ~= nil then
        return self.global.settings[category][setting]
    end
    
    -- Return default if no setting found
    return default
end

-- Set a setting value
function AM.DB:SetSetting(path, value, charSpecific)
    local parts = {strsplit(".", path)}
    local category = parts[1]
    local setting = parts[2]
    
    if not category or not setting then
        return false
    end
    
    if charSpecific then
        -- Ensure category exists
        if not self.char.settings[category] then
            self.char.settings[category] = {}
        end
        
        -- Set character-specific setting
        self.char.settings[category][setting] = value
    else
        -- Ensure category exists
        if not self.global.settings[category] then
            self.global.settings[category] = {}
        end
        
        -- Set global setting
        self.global.settings[category][setting] = value
    end
    
    return true
end

-- Reset settings to default
function AM.DB:ResetSettings(charSpecific)
    if charSpecific then
        self.char.settings = {}
    else
        self.global.settings = AM.Util.DeepCopy(AM.Constants.DEFAULT_SETTINGS)
    end
end

-- Save auction data
function AM.DB:SaveAuctionData(itemKey, auctionData)
    if not itemKey or not auctionData then return end
    
    -- Store auction data
    self.realm.auctions[itemKey] = auctionData
    
    -- Update last scan time
    self.realm.lastScan = time()
    
    -- Update market statistics
    self:UpdateMarketStats(itemKey, auctionData)
    
    -- Update historical data
    self:UpdateHistoricalData(itemKey, auctionData)
end

-- Update market statistics for an item
function AM.DB:UpdateMarketStats(itemKey, auctionData)
    if not itemKey or not auctionData then return end
    
    -- Initialize market stats if needed
    if not self.realm.marketStats[itemKey] then
        self.realm.marketStats[itemKey] = {
            marketValue = 0,
            historicalValue = 0,
            minPrice = 0,
            maxPrice = 0,
            stdDev = 0,
            soldPerDay = 0,
            lastUpdated = 0,
        }
    end
    
    local stats = self.realm.marketStats[itemKey]
    
    -- Calculate market value (weighted average of current auctions)
    local totalValue = 0
    local totalQuantity = 0
    local minPrice = nil
    local maxPrice = 0
    local prices = {}
    
    -- Process auction data
    for _, auction in ipairs(auctionData) do
        if auction.buyout and auction.buyout > 0 then
            local pricePerItem = auction.buyout / auction.count
            
            -- Track min/max prices
            if not minPrice or pricePerItem < minPrice then
                minPrice = pricePerItem
            end
            
            if pricePerItem > maxPrice then
                maxPrice = pricePerItem
            end
            
            -- Add to weighted average calculation
            totalValue = totalValue + (pricePerItem * auction.count)
            totalQuantity = totalQuantity + auction.count
            
            -- Store price for standard deviation calculation
            table.insert(prices, pricePerItem)
        end
    end
    
    -- Update market value if we have data
    if totalQuantity > 0 then
        -- Calculate new market value with a weight towards previous value for stability
        local newMarketValue = totalValue / totalQuantity
        if stats.marketValue > 0 then
            stats.marketValue = (stats.marketValue * 0.7) + (newMarketValue * 0.3)
        else
            stats.marketValue = newMarketValue
        end
        
        -- Update min/max prices
        stats.minPrice = minPrice
        stats.maxPrice = maxPrice
        
        -- Calculate standard deviation
        if #prices > 1 then
            local sum = 0
            for _, price in ipairs(prices) do
                sum = sum + price
            end
            local mean = sum / #prices
            
            local variance = 0
            for _, price in ipairs(prices) do
                variance = variance + ((price - mean) ^ 2)
            end
            variance = variance / #prices
            
            stats.stdDev = math.sqrt(variance)
        end
    end
    
    -- Update timestamp
    stats.lastUpdated = time()
end

-- Update historical price data
function AM.DB:UpdateHistoricalData(itemKey, auctionData)
    if not itemKey or not auctionData then return end
    
    -- Initialize history if needed
    if not self.realm.history[itemKey] then
        self.realm.history[itemKey] = {
            daily = {},
            weekly = {},
            monthly = {},
        }
    end
    
    local history = self.realm.history[itemKey]
    local currentTime = time()
    local dayTimestamp = math.floor(currentTime / 86400) * 86400 -- Round to start of day
    
    -- Calculate daily snapshot
    local minBuyout = nil
    local totalBuyout = 0
    local totalQuantity = 0
    
    for _, auction in ipairs(auctionData) do
        if auction.buyout and auction.buyout > 0 then
            local pricePerItem = auction.buyout / auction.count
            
            if not minBuyout or pricePerItem < minBuyout then
                minBuyout = pricePerItem
            end
            
            totalBuyout = totalBuyout + (pricePerItem * auction.count)
            totalQuantity = totalQuantity + auction.count
        end
    end
    
    -- Only update if we have data
    if totalQuantity > 0 then
        local avgBuyout = totalBuyout / totalQuantity
        
        -- Update or create daily record
        history.daily[dayTimestamp] = {
            minBuyout = minBuyout,
            avgBuyout = avgBuyout,
            quantity = totalQuantity,
        }
        
        -- Update weekly and monthly aggregates
        self:UpdateAggregateHistory(itemKey)
    end
    
    -- Prune old data if needed
    local dataRetention = self:GetSetting("general.dataRetention", 30)
    self:PruneHistoricalData(itemKey, currentTime - (dataRetention * 86400))
end

-- Update weekly and monthly aggregate history
function AM.DB:UpdateAggregateHistory(itemKey)
    if not itemKey or not self.realm.history[itemKey] then return end
    
    local history = self.realm.history[itemKey]
    local currentTime = time()
    local weekTimestamp = math.floor(currentTime / 604800) * 604800 -- Round to start of week
    local monthTimestamp = math.floor(currentTime / 2592000) * 2592000 -- Round to start of month (30 days)
    
    -- Process daily data for weekly aggregate
    local weeklyData = {
        minBuyout = nil,
        totalBuyout = 0,
        totalQuantity = 0,
    }
    
    for timestamp, data in pairs(history.daily) do
        -- Only include data from current week
        if timestamp >= weekTimestamp then
            if not weeklyData.minBuyout or data.minBuyout < weeklyData.minBuyout then
                weeklyData.minBuyout = data.minBuyout
            end
            
            weeklyData.totalBuyout = weeklyData.totalBuyout + (data.avgBuyout * data.quantity)
            weeklyData.totalQuantity = weeklyData.totalQuantity + data.quantity
        end
    end
    
    -- Update weekly record if we have data
    if weeklyData.totalQuantity > 0 then
        history.weekly[weekTimestamp] = {
            minBuyout = weeklyData.minBuyout,
            avgBuyout = weeklyData.totalBuyout / weeklyData.totalQuantity,
            quantity = weeklyData.totalQuantity,
        }
    end
    
    -- Process daily data for monthly aggregate
    local monthlyData = {
        minBuyout = nil,
        totalBuyout = 0,
        totalQuantity = 0,
    }
    
    for timestamp, data in pairs(history.daily) do
        -- Only include data from current month
        if timestamp >= monthTimestamp then
            if not monthlyData.minBuyout or data.minBuyout < monthlyData.minBuyout then
                monthlyData.minBuyout = data.minBuyout
            end
            
            monthlyData.totalBuyout = monthlyData.totalBuyout + (data.avgBuyout * data.quantity)
            monthlyData.totalQuantity = monthlyData.totalQuantity + data.quantity
        end
    end
    
    -- Update monthly record if we have data
    if monthlyData.totalQuantity > 0 then
        history.monthly[monthTimestamp] = {
            minBuyout = monthlyData.minBuyout,
            avgBuyout = monthlyData.totalBuyout / monthlyData.totalQuantity,
            quantity = monthlyData.totalQuantity,
        }
    end
end

-- Prune historical data older than specified timestamp
function AM.DB:PruneHistoricalData(itemKey, olderThan)
    if not itemKey or not self.realm.history[itemKey] then return end
    
    local history = self.realm.history[itemKey]
    
    -- Prune daily data
    for timestamp in pairs(history.daily) do
        if timestamp < olderThan then
            history.daily[timestamp] = nil
        end
    end
    
    -- Prune weekly data (keep 3 months)
    for timestamp in pairs(history.weekly) do
        if timestamp < (olderThan - 5184000) then -- 60 days older
            history.weekly[timestamp] = nil
        end
    end
    
    -- Prune monthly data (keep 1 year)
    for timestamp in pairs(history.monthly) do
        if timestamp < (olderThan - 31104000) then -- 360 days older
            history.monthly[timestamp] = nil
        end
    end
end

-- Get item price
function AM.DB:GetItemPrice(itemKey, priceType)
    if not itemKey then return nil end
    
    -- Default to market value if no price type specified
    priceType = priceType or AM.Constants.PRICE_TYPE_MARKET
    
    -- Check if we have market stats for this item
    if not self.realm.marketStats[itemKey] then
        return nil
    end
    
    local stats = self.realm.marketStats[itemKey]
    
    -- Return requested price type
    if priceType == AM.Constants.PRICE_TYPE_MARKET then
        return stats.marketValue
    elseif priceType == AM.Constants.PRICE_TYPE_HISTORICAL then
        return stats.historicalValue
    elseif priceType == AM.Constants.PRICE_TYPE_MINIMUM then
        return stats.minPrice
    elseif priceType == AM.Constants.PRICE_TYPE_MAXIMUM then
        return stats.maxPrice
    elseif priceType == AM.Constants.PRICE_TYPE_RECENT then
        -- Get most recent daily price
        local history = self.realm.history[itemKey]
        if history and history.daily then
            local mostRecentTimestamp = 0
            local mostRecentPrice = nil
            
            for timestamp, data in pairs(history.daily) do
                if timestamp > mostRecentTimestamp then
                    mostRecentTimestamp = timestamp
                    mostRecentPrice = data.minBuyout
                end
            end
            
            return mostRecentPrice
        end
    end
    
    return nil
end

-- Get item info from cache or game API
function AM.DB:GetItemInfo(itemID)
    if not itemID then return nil end
    
    -- Check cache first
    if self.realm.itemCache[itemID] then
        local cachedInfo = self.realm.itemCache[itemID]
        
        -- Return cached info if it's recent enough
        if cachedInfo.lastUpdated > (time() - 86400) then -- 1 day cache
            return cachedInfo
        end
    end
    
    -- Get info from game API
    local itemInfo = AM.Util.GetItemInfo(itemID)
    
    -- Cache the result if successful
    if itemInfo then
        self.realm.itemCache[itemID] = itemInfo
        self.realm.itemCache[itemID].lastUpdated = time()
    end
    
    return itemInfo
end

-- Export data in specified format
function AM.DB:ExportData(format, selection)
    -- Implement data export functionality
    -- This is a placeholder for future implementation
end

-- Import data with optional merging
function AM.DB:ImportData(data, merge)
    -- Implement data import functionality
    -- This is a placeholder for future implementation
end
