-- AuctionMaster Pricing Module
local addonName, AM = ...
local L = AM.L

-- Create module namespace
AM.Pricing = {}
local Pricing = AM.Pricing

-- Initialize the pricing module
function Pricing:Initialize()
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Pricing module initialized")
end

-- Calculate market value for an item
function Pricing:CalculateMarketValue(itemKey)
    if not itemKey then return nil end
    
    -- Get auction data
    local auctionData = AM.DB.realm.auctions[itemKey]
    if not auctionData or #auctionData == 0 then
        return nil
    end
    
    -- Calculate weighted average of current auctions
    local totalValue = 0
    local totalQuantity = 0
    
    for _, auction in ipairs(auctionData) do
        if auction.buyout and auction.buyout > 0 then
            local pricePerItem = auction.buyout / auction.count
            totalValue = totalValue + (pricePerItem * auction.count)
            totalQuantity = totalQuantity + auction.count
        end
    end
    
    if totalQuantity > 0 then
        return totalValue / totalQuantity
    end
    
    return nil
end

-- Calculate historical value for an item
function Pricing:CalculateHistoricalValue(itemKey)
    if not itemKey then return nil end
    
    -- Get historical data
    local history = AM.DB.realm.history[itemKey]
    if not history then
        return nil
    end
    
    -- Calculate weighted average of historical prices
    local totalValue = 0
    local totalQuantity = 0
    local totalWeight = 0
    
    -- Process daily data with higher weight for more recent data
    local currentTime = time()
    for timestamp, data in pairs(history.daily) do
        -- Calculate age in days
        local ageInDays = (currentTime - timestamp) / 86400
        -- Weight decreases with age (more recent = higher weight)
        local weight = math.max(0, 30 - ageInDays) / 30
        
        totalValue = totalValue + (data.avgBuyout * data.quantity * weight)
        totalQuantity = totalQuantity + (data.quantity * weight)
        totalWeight = totalWeight + weight
    end
    
    if totalQuantity > 0 then
        return totalValue / totalQuantity
    end
    
    return nil
end

-- Calculate minimum buyout for an item
function Pricing:CalculateMinBuyout(itemKey)
    if not itemKey then return nil end
    
    -- Get auction data
    local auctionData = AM.DB.realm.auctions[itemKey]
    if not auctionData or #auctionData == 0 then
        return nil
    end
    
    -- Find minimum buyout
    local minBuyout = nil
    
    for _, auction in ipairs(auctionData) do
        if auction.buyout and auction.buyout > 0 then
            local pricePerItem = auction.buyout / auction.count
            if not minBuyout or pricePerItem < minBuyout then
                minBuyout = pricePerItem
            end
        end
    end
    
    return minBuyout
end

-- Calculate suggested posting price
function Pricing:CalculatePostingPrice(itemKey, strategy)
    if not itemKey then return nil end
    
    -- Default strategy
    strategy = strategy or "market"
    
    -- Get price data
    local marketValue = self:CalculateMarketValue(itemKey)
    local minBuyout = self:CalculateMinBuyout(itemKey)
    local historicalValue = self:CalculateHistoricalValue(itemKey)
    
    -- Calculate based on strategy
    if strategy == "market" then
        -- Use market value if available, otherwise historical
        return marketValue or historicalValue
    elseif strategy == "undercut" then
        -- Undercut the lowest price by a small amount
        if minBuyout then
            local undercutAmount = AM.DB:GetSetting("posting.undercut", 1)
            return math.max(1, minBuyout - undercutAmount)
        else
            return marketValue or historicalValue
        end
    elseif strategy == "fixed" then
        -- Use a fixed percentage of market value
        if marketValue then
            local percentage = AM.DB:GetSetting("posting.fixedPricePercentage", 100)
            return marketValue * (percentage / 100)
        else
            return historicalValue
        end
    end
    
    -- Fallback to market value
    return marketValue or historicalValue or 0
end

-- Calculate price trend
function Pricing:CalculatePriceTrend(itemKey, period)
    if not itemKey then return nil end
    
    -- Default to daily period
    period = period or AM.Constants.TIME_PERIOD_DAILY
    
    -- Get historical data
    local history = AM.DB.realm.history[itemKey]
    if not history then
        return nil
    end
    
    -- Select data based on period
    local data
    if period == AM.Constants.TIME_PERIOD_DAILY then
        data = history.daily
    elseif period == AM.Constants.TIME_PERIOD_WEEKLY then
        data = history.weekly
    elseif period == AM.Constants.TIME_PERIOD_MONTHLY then
        data = history.monthly
    else
        return nil
    end
    
    -- Need at least two data points for trend
    if not data or table.getn(data) < 2 then
        return nil
    end
    
    -- Sort timestamps
    local timestamps = {}
    for timestamp in pairs(data) do
        table.insert(timestamps, timestamp)
    end
    table.sort(timestamps)
    
    -- Calculate trend using linear regression
    local n = #timestamps
    local sumX = 0
    local sumY = 0
    local sumXY = 0
    local sumX2 = 0
    
    for i, timestamp in ipairs(timestamps) do
        local x = i  -- Use index as x value for simplicity
        local y = data[timestamp].avgBuyout
        
        sumX = sumX + x
        sumY = sumY + y
        sumXY = sumXY + (x * y)
        sumX2 = sumX2 + (x * x)
    end
    
    local slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
    
    -- Return trend direction and magnitude
    if math.abs(slope) < 0.01 then
        return 0  -- Stable
    elseif slope > 0 then
        return 1  -- Rising
    else
        return -1  -- Falling
    end
end

-- Calculate market volatility
function Pricing:CalculateVolatility(itemKey)
    if not itemKey then return nil end
    
    -- Get market stats
    local stats = AM.DB.realm.marketStats[itemKey]
    if not stats or not stats.stdDev or not stats.marketValue or stats.marketValue == 0 then
        return nil
    end
    
    -- Calculate coefficient of variation (stdDev / mean)
    return stats.stdDev / stats.marketValue
end

-- Calculate potential profit
function Pricing:CalculateProfit(itemKey, costBasis)
    if not itemKey or not costBasis then return nil end
    
    -- Get minimum buyout
    local minBuyout = self:CalculateMinBuyout(itemKey)
    if not minBuyout then
        return nil
    end
    
    -- Calculate profit
    local profit = minBuyout - costBasis
    
    -- Calculate deposit cost if available
    local depositCost = self:CalculateDepositCost(itemKey)
    if depositCost then
        profit = profit - depositCost
    end
    
    -- Calculate auction house cut (5%)
    local ahCut = minBuyout * 0.05
    profit = profit - ahCut
    
    return profit
end

-- Calculate deposit cost
function Pricing:CalculateDepositCost(itemKey, duration)
    if not itemKey then return nil end
    
    -- Default to 24 hour duration
    duration = duration or AM.Constants.AUCTION_DURATION_24
    
    -- Get item info
    local itemID = tonumber(string.match(itemKey, "^(%d+):"))
    if not itemID then return nil end
    
    local itemInfo = AM.DB:GetItemInfo(itemID)
    if not itemInfo or not itemInfo.vendorSell then
        return nil
    end
    
    -- Calculate deposit (4 hours = 1x, 8 hours = 2x, 24 hours = 4x vendor price)
    local multiplier = 1
    if duration == AM.Constants.AUCTION_DURATION_12 then
        multiplier = 2
    elseif duration == AM.Constants.AUCTION_DURATION_24 then
        multiplier = 3
    elseif duration == AM.Constants.AUCTION_DURATION_48 then
        multiplier = 4
    end
    
    return math.floor(itemInfo.vendorSell * multiplier * 0.0375)  -- 3.75% of vendor price
end

-- Get price history data for charts
function Pricing:GetPriceHistoryData(itemKey, period, maxPoints)
    if not itemKey then return nil end
    
    -- Default to daily period and 30 points
    period = period or AM.Constants.TIME_PERIOD_DAILY
    maxPoints = maxPoints or 30
    
    -- Get historical data
    local history = AM.DB.realm.history[itemKey]
    if not history then
        return nil
    end
    
    -- Select data based on period
    local data
    if period == AM.Constants.TIME_PERIOD_DAILY then
        data = history.daily
    elseif period == AM.Constants.TIME_PERIOD_WEEKLY then
        data = history.weekly
    elseif period == AM.Constants.TIME_PERIOD_MONTHLY then
        data = history.monthly
    else
        return nil
    end
    
    -- Sort timestamps
    local timestamps = {}
    for timestamp in pairs(data) do
        table.insert(timestamps, timestamp)
    end
    table.sort(timestamps)
    
    -- Limit to maxPoints most recent
    if #timestamps > maxPoints then
        local start = #timestamps - maxPoints + 1
        local limitedTimestamps = {}
        for i = start, #timestamps do
            table.insert(limitedTimestamps, timestamps[i])
        end
        timestamps = limitedTimestamps
    end
    
    -- Build result
    local result = {
        timestamps = {},
        minBuyouts = {},
        avgBuyouts = {},
        quantities = {}
    }
    
    for _, timestamp in ipairs(timestamps) do
        table.insert(result.timestamps, timestamp)
        table.insert(result.minBuyouts, data[timestamp].minBuyout)
        table.insert(result.avgBuyouts, data[timestamp].avgBuyout)
        table.insert(result.quantities, data[timestamp].quantity)
    end
    
    return result
end

-- Calculate deal score (0-100)
function Pricing:CalculateDealScore(itemKey, currentPrice)
    if not itemKey or not currentPrice then return nil end
    
    -- Get market value and historical value
    local marketValue = self:CalculateMarketValue(itemKey)
    local historicalValue = self:CalculateHistoricalValue(itemKey)
    
    if not marketValue and not historicalValue then
        return nil
    end
    
    -- Use market value if available, otherwise historical
    local referencePrice = marketValue or historicalValue
    
    -- Calculate discount percentage
    local discount = 1 - (currentPrice / referencePrice)
    
    -- Convert to score (0-100)
    local score = math.floor(discount * 100)
    
    -- Cap between 0 and 100
    return math.max(0, math.min(100, score))
end

-- Get custom price based on formula
function Pricing:GetCustomPrice(itemKey, formula)
    if not itemKey or not formula then return nil end
    
    -- Simple formula parser
    -- Supports: min(), max(), avg(), first(), dbmarket, dbhistorical, dbminbuyout, vendorsell
    
    -- Replace price sources with actual values
    local marketValue = self:CalculateMarketValue(itemKey) or 0
    local historicalValue = self:CalculateHistoricalValue(itemKey) or 0
    local minBuyout = self:CalculateMinBuyout(itemKey) or 0
    
    -- Get item info for vendor sell price
    local itemID = tonumber(string.match(itemKey, "^(%d+):"))
    local vendorSell = 0
    if itemID then
        local itemInfo = AM.DB:GetItemInfo(itemID)
        if itemInfo and itemInfo.vendorSell then
            vendorSell = itemInfo.vendorSell
        end
    end
    
    -- Replace price sources
    local parsedFormula = formula
    parsedFormula = string.gsub(parsedFormula, "dbmarket", tostring(marketValue))
    parsedFormula = string.gsub(parsedFormula, "dbhistorical", tostring(historicalValue))
    parsedFormula = string.gsub(parsedFormula, "dbminbuyout", tostring(minBuyout))
    parsedFormula = string.gsub(parsedFormula, "vendorsell", tostring(vendorSell))
    
    -- Handle min/max/avg functions
    -- This is a simplified implementation and doesn't handle nested functions
    
    -- min function
    parsedFormula = string.gsub(parsedFormula, "min%(([^%)]+)%)", function(args)
        local values = {strsplit(",", args)}
        local minVal = nil
        for _, val in ipairs(values) do
            local num = tonumber(val)
            if num and (minVal == nil or num < minVal) then
                minVal = num
            end
        end
        return tostring(minVal or 0)
    end)
    
    -- max function
    parsedFormula = string.gsub(parsedFormula, "max%(([^%)]+)%)", function(args)
        local values = {strsplit(",", args)}
        local maxVal = 0
        for _, val in ipairs(values) do
            local num = tonumber(val)
            if num and num > maxVal then
                maxVal = num
            end
        end
        return tostring(maxVal)
    end)
    
    -- avg function
    parsedFormula = string.gsub(parsedFormula, "avg%(([^%)]+)%)", function(args)
        local values = {strsplit(",", args)}
        local sum = 0
        local count = 0
        for _, val in ipairs(values) do
            local num = tonumber(val)
            if num then
                sum = sum + num
                count = count + 1
            end
        end
        return tostring(count > 0 and (sum / count) or 0)
    end)
    
    -- first function (first non-zero value)
    parsedFormula = string.gsub(parsedFormula, "first%(([^%)]+)%)", function(args)
        local values = {strsplit(",", args)}
        for _, val in ipairs(values) do
            local num = tonumber(val)
            if num and num > 0 then
                return tostring(num)
            end
        end
        return "0"
    end)
    
    -- Try to evaluate the formula
    local func, err = loadstring("return " .. parsedFormula)
    if func then
        local success, result = pcall(func)
        if success and type(result) == "number" then
            return result
        end
    end
    
    -- Return nil if evaluation failed
    return nil
end
