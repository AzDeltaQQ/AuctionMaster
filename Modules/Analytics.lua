-- AuctionMaster Analytics Module
local addonName, AM = ...
local L = AM.L

-- Create module namespace
AM.Analytics = {}
local Analytics = AM.Analytics

-- Initialize the analytics module
function Analytics:Initialize()
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Analytics module initialized")
end

-- Get top sellers for an item
function Analytics:GetTopSellers(itemKey, limit)
    if not itemKey then return {} end
    limit = limit or 5
    
    -- Get auction data
    local auctionData = AM.DB.realm.auctions[itemKey]
    if not auctionData or #auctionData == 0 then
        return {}
    end
    
    -- Count auctions by seller
    local sellerCounts = {}
    local sellerTotals = {}
    
    for _, auction in ipairs(auctionData) do
        if auction.owner then
            sellerCounts[auction.owner] = (sellerCounts[auction.owner] or 0) + 1
            sellerTotals[auction.owner] = (sellerTotals[auction.owner] or 0) + auction.count
        end
    end
    
    -- Convert to array for sorting
    local sellers = {}
    for seller, count in pairs(sellerCounts) do
        table.insert(sellers, {
            name = seller,
            auctions = count,
            quantity = sellerTotals[seller]
        })
    end
    
    -- Sort by number of auctions
    table.sort(sellers, function(a, b)
        return a.auctions > b.auctions
    end)
    
    -- Limit results
    if #sellers > limit then
        local limitedSellers = {}
        for i = 1, limit do
            table.insert(limitedSellers, sellers[i])
        end
        sellers = limitedSellers
    end
    
    return sellers
end

-- Get market activity metrics
function Analytics:GetMarketActivity(itemKey, period)
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
    
    -- Calculate metrics
    local totalQuantity = 0
    local totalValue = 0
    local minPrice = nil
    local maxPrice = 0
    local dataPoints = 0
    
    for _, entry in pairs(data) do
        totalQuantity = totalQuantity + entry.quantity
        totalValue = totalValue + (entry.avgBuyout * entry.quantity)
        
        if not minPrice or entry.minBuyout < minPrice then
            minPrice = entry.minBuyout
        end
        
        if entry.avgBuyout > maxPrice then
            maxPrice = entry.avgBuyout
        end
        
        dataPoints = dataPoints + 1
    end
    
    -- Return metrics
    return {
        totalQuantity = totalQuantity,
        averageQuantity = dataPoints > 0 and (totalQuantity / dataPoints) or 0,
        averagePrice = totalQuantity > 0 and (totalValue / totalQuantity) or 0,
        minPrice = minPrice or 0,
        maxPrice = maxPrice,
        priceRange = maxPrice - (minPrice or 0),
        dataPoints = dataPoints
    }
end

-- Get price volatility
function Analytics:GetPriceVolatility(itemKey, period)
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
    
    -- Need at least two data points
    if not data or table.getn(data) < 2 then
        return nil
    end
    
    -- Calculate standard deviation of prices
    local prices = {}
    for _, entry in pairs(data) do
        table.insert(prices, entry.avgBuyout)
    end
    
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
    
    local stdDev = math.sqrt(variance)
    
    -- Calculate coefficient of variation (stdDev / mean)
    local volatility = mean > 0 and (stdDev / mean) or 0
    
    return {
        stdDev = stdDev,
        mean = mean,
        volatility = volatility,
        interpretation = self:InterpretVolatility(volatility)
    }
end

-- Interpret volatility value
function Analytics:InterpretVolatility(volatility)
    if volatility < 0.05 then
        return "very_stable"
    elseif volatility < 0.1 then
        return "stable"
    elseif volatility < 0.2 then
        return "moderate"
    elseif volatility < 0.3 then
        return "volatile"
    else
        return "very_volatile"
    end
end

-- Get profit opportunities
function Analytics:GetProfitOpportunities(itemKey, costBasis)
    if not itemKey or not costBasis then return nil end
    
    -- Get market data
    local marketValue = AM.Pricing:CalculateMarketValue(itemKey)
    local minBuyout = AM.Pricing:CalculateMinBuyout(itemKey)
    
    if not marketValue or not minBuyout then
        return nil
    end
    
    -- Calculate profit margins
    local marketProfit = marketValue - costBasis
    local marketMargin = costBasis > 0 and (marketProfit / costBasis) or 0
    
    local minProfit = minBuyout - costBasis
    local minMargin = costBasis > 0 and (minProfit / costBasis) or 0
    
    -- Calculate deposit cost
    local depositCost = AM.Pricing:CalculateDepositCost(itemKey)
    
    -- Calculate auction house cut (5%)
    local ahCutMarket = marketValue * 0.05
    local ahCutMin = minBuyout * 0.05
    
    -- Calculate net profit
    local netMarketProfit = marketProfit - (depositCost or 0) - ahCutMarket
    local netMinProfit = minProfit - (depositCost or 0) - ahCutMin
    
    -- Return profit data
    return {
        marketValue = marketValue,
        minBuyout = minBuyout,
        costBasis = costBasis,
        depositCost = depositCost or 0,
        ahCutMarket = ahCutMarket,
        ahCutMin = ahCutMin,
        marketProfit = marketProfit,
        marketMargin = marketMargin,
        minProfit = minProfit,
        minMargin = minMargin,
        netMarketProfit = netMarketProfit,
        netMinProfit = netMinProfit,
        profitable = netMinProfit > 0
    }
end

-- Get sales velocity
function Analytics:GetSalesVelocity(itemKey, period)
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
    
    -- Calculate total quantity and time span
    local totalQuantity = 0
    local minTimestamp = nil
    local maxTimestamp = 0
    
    for timestamp, entry in pairs(data) do
        totalQuantity = totalQuantity + entry.quantity
        
        if not minTimestamp or timestamp < minTimestamp then
            minTimestamp = timestamp
        end
        
        if timestamp > maxTimestamp then
            maxTimestamp = timestamp
        end
    end
    
    -- Calculate time span in days
    local timeSpan = maxTimestamp and minTimestamp and ((maxTimestamp - minTimestamp) / 86400) or 1
    if timeSpan < 1 then timeSpan = 1 end
    
    -- Calculate sales per day
    local salesPerDay = totalQuantity / timeSpan
    
    return {
        totalQuantity = totalQuantity,
        timeSpan = timeSpan,
        salesPerDay = salesPerDay
    }
end

-- Get market competition analysis
function Analytics:GetCompetitionAnalysis(itemKey)
    if not itemKey then return nil end
    
    -- Get auction data
    local auctionData = AM.DB.realm.auctions[itemKey]
    if not auctionData or #auctionData == 0 then
        return nil
    end
    
    -- Count unique sellers
    local sellers = {}
    local totalAuctions = #auctionData
    local totalQuantity = 0
    
    for _, auction in ipairs(auctionData) do
        if auction.owner then
            sellers[auction.owner] = true
        end
        totalQuantity = totalQuantity + auction.count
    end
    
    local uniqueSellers = 0
    for _ in pairs(sellers) do
        uniqueSellers = uniqueSellers + 1
    end
    
    -- Get top sellers
    local topSellers = self:GetTopSellers(itemKey, 3)
    
    -- Calculate market concentration (top 3 sellers' share)
    local top3Quantity = 0
    for _, seller in ipairs(topSellers) do
        top3Quantity = top3Quantity + seller.quantity
    end
    
    local marketConcentration = totalQuantity > 0 and (top3Quantity / totalQuantity) or 0
    
    -- Return competition data
    return {
        uniqueSellers = uniqueSellers,
        totalAuctions = totalAuctions,
        totalQuantity = totalQuantity,
        auctionsPerSeller = uniqueSellers > 0 and (totalAuctions / uniqueSellers) or 0,
        quantityPerSeller = uniqueSellers > 0 and (totalQuantity / uniqueSellers) or 0,
        topSellers = topSellers,
        marketConcentration = marketConcentration,
        competitionLevel = self:InterpretCompetition(uniqueSellers, marketConcentration)
    }
end

-- Interpret competition level
function Analytics:InterpretCompetition(uniqueSellers, marketConcentration)
    if uniqueSellers <= 1 then
        return "monopoly"
    elseif uniqueSellers <= 3 and marketConcentration > 0.8 then
        return "oligopoly"
    elseif uniqueSellers <= 5 then
        return "limited"
    elseif uniqueSellers <= 10 then
        return "moderate"
    else
        return "high"
    end
end

-- Get market summary for dashboard
function Analytics:GetMarketSummary()
    -- Get realm data
    local realmData = AM.DB.realm
    
    -- Count total items tracked
    local totalItems = 0
    for _ in pairs(realmData.marketStats or {}) do
        totalItems = totalItems + 1
    end
    
    -- Find most active markets
    local itemActivity = {}
    for itemKey, history in pairs(realmData.history or {}) do
        local activity = 0
        for _, entry in pairs(history.daily or {}) do
            activity = activity + entry.quantity
        end
        
        if activity > 0 then
            table.insert(itemActivity, {
                itemKey = itemKey,
                activity = activity
            })
        end
    end
    
    -- Sort by activity
    table.sort(itemActivity, function(a, b)
        return a.activity > b.activity
    end)
    
    -- Get top 5 most active markets
    local topMarkets = {}
    for i = 1, math.min(5, #itemActivity) do
        local itemKey = itemActivity[i].itemKey
        local itemID = tonumber(string.match(itemKey, "^(%d+):"))
        local itemInfo = itemID and AM.DB:GetItemInfo(itemID) or nil
        
        table.insert(topMarkets, {
            itemKey = itemKey,
            itemID = itemID,
            name = itemInfo and itemInfo.name or "Unknown Item",
            activity = itemActivity[i].activity
        })
    end
    
    -- Get last scan info
    local lastScan = realmData.lastScan or 0
    local lastFullScan = realmData.scanStats and realmData.scanStats.lastFullScan or 0
    
    -- Return summary
    return {
        totalItems = totalItems,
        lastScan = lastScan,
        lastScanTime = AM.Util.GetTimeDifference(lastScan),
        lastFullScan = lastFullScan,
        lastFullScanTime = AM.Util.GetTimeDifference(lastFullScan),
        topMarkets = topMarkets
    }
end

-- Generate market report for an item
function Analytics:GenerateMarketReport(itemKey)
    if not itemKey then return nil end
    
    -- Get item info
    local itemID = tonumber(string.match(itemKey, "^(%d+):"))
    local itemInfo = itemID and AM.DB:GetItemInfo(itemID) or nil
    
    if not itemInfo then
        return nil
    end
    
    -- Gather all analytics
    local report = {
        itemKey = itemKey,
        itemID = itemID,
        name = itemInfo.name,
        link = itemInfo.link,
        quality = itemInfo.quality,
        level = itemInfo.level,
        
        -- Price data
        marketValue = AM.Pricing:CalculateMarketValue(itemKey),
        historicalValue = AM.Pricing:CalculateHistoricalValue(itemKey),
        minBuyout = AM.Pricing:CalculateMinBuyout(itemKey),
        
        -- Market activity
        activity = self:GetMarketActivity(itemKey),
        
        -- Price trend
        priceTrend = AM.Pricing:CalculatePriceTrend(itemKey),
        
        -- Volatility
        volatility = self:GetPriceVolatility(itemKey),
        
        -- Sales velocity
        salesVelocity = self:GetSalesVelocity(itemKey),
        
        -- Competition
        competition = self:GetCompetitionAnalysis(itemKey),
        
        -- Price history data for charts
        priceHistory = AM.Pricing:GetPriceHistoryData(itemKey)
    }
    
    return report
end
