-- AuctionMaster Scanner Module
local addonName, AM = ...
local L = AM.L

-- Create module namespace
AM.Scanner = {}
local Scanner = AM.Scanner

-- Local variables
local scanInProgress = false
local scanType = nil
local scanStartTime = 0
local scanResults = {}
local currentQuery = {} -- Holds the parameters for the current auction query
local currentPage = 0   -- 0-indexed internally for API calls
local totalPages = 0    -- Total pages for the current scan, determined after first query
local scanThrottle = 100 -- ms between queries, will be loaded from settings
local lastScanTime = 0  -- Timestamp of the last query sent
local searchCache = {}

-- Initialize the scanner module
function Scanner:Initialize()
    -- Load settings
    scanThrottle = AM.DB:GetSetting("scanning.scanThrottle", 100)
    
    -- Register for events
    AM.Events:AddCallback("AUCTION_ITEM_LIST_UPDATE", function() self:OnAuctionUpdate() end)
    AM.Events:AddCallback("AUCTION_HOUSE_CLOSED", function() self:OnAuctionHouseClosed() end)
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Scanner module initialized")
end

-- Start a full auction house scan or a targeted search
function Scanner:StartScan(scanParams)
    -- Check if auction house is open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_AH_CLOSED"))
        return false
    end
    
    -- Check if a scan is already in progress
    if scanInProgress then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.WARNING, L:Get("ERROR_SCAN_IN_PROGRESS"))
        return false
    end
    
    -- Initialize scan parameters
    scanParams = scanParams or {}
    scanType = scanParams.type or AM.Constants.SCAN_TYPE_FULL
    
    -- Reset scan data
    scanResults = {}
    currentPage = 0 -- Start at page 0 for the first query
    totalPages = 0  -- Will be determined after the first query's results
    scanStartTime = GetTime()
    scanInProgress = true
    
    -- Store search term if it's a targeted scan
    if scanType == AM.Constants.SCAN_TYPE_TARGETED and scanParams.searchTerm then
        currentQuery.searchTerm = scanParams.searchTerm -- Store for QueryCurrentPage
    else
        currentQuery.searchTerm = nil -- Clear for other scan types
    end
    
    -- Fire scan start event
    AM.Events:FireEvent(AM.Constants.EVENTS.SCAN_START, scanType)
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Scan started. Type: " .. scanType .. ". Querying page 0.")
    self:QueryCurrentPage() -- Start by querying the first page (page 0)
    
    return true
end

-- Search for specific items (convenience wrapper for StartScan)
function Scanner:Search(searchTerm, exact)
    -- Check if auction house is open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_AH_CLOSED"))
        return false
    end
    
    -- Check if a scan is already in progress
    if scanInProgress then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.WARNING, L:Get("ERROR_SCAN_IN_PROGRESS"))
        return false
    end
    
    -- Initialize search parameters
    local searchParams = {
        type = AM.Constants.SCAN_TYPE_TARGETED,
        searchTerm = searchTerm,
        exact = exact or false -- 'exact' might be used in query setup later if needed
    }
    
    -- Check search cache for recent results
    local cacheKey = searchTerm:lower()
    if searchCache[cacheKey] and (GetTime() - searchCache[cacheKey].time < 60) then
        -- Use cached results if less than 60 seconds old
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Using cached search results for: " .. searchTerm)
        -- This part needs adjustment: cached results should be displayed, not re-scanned.
        -- For now, we'll proceed with a new scan as per existing logic, cache update is in EndScan.
        -- To actually use cache and skip scan:
        -- AM.Events:FireEvent(AM.Constants.EVENTS.SCAN_COMPLETE, searchCache[cacheKey].results, #searchCache[cacheKey].results, 0)
        -- print("|cFF00CCFF" .. L:Get("SCAN_COMPLETE_CACHED", #searchCache[cacheKey].results) .. "|r")
        -- return true 
    end
    
    -- Start the search scan
    return self:StartScan(searchParams)
end

-- Prepare and execute the query for the current page
function Scanner:QueryCurrentPage()
    if not scanInProgress then return end

    -- Check if auction house is still open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        self:EndScan("ERROR_AH_CLOSED")
        return
    end

    -- Prepare query based on scan type
    if scanType == AM.Constants.SCAN_TYPE_FULL then
        currentQuery = {
            name = "", minLevel = 0, maxLevel = 0, invTypeIndex = 0,
            classIndex = 0, subclassIndex = 0, page = currentPage,
            isUsable = false, qualityIndex = 0,
            getAll = AM.DB:GetSetting("scanning.getAll", false)
        }
    elseif scanType == AM.Constants.SCAN_TYPE_TARGETED then
        currentQuery = {
            name = currentQuery.searchTerm or "", minLevel = 0, maxLevel = 0, invTypeIndex = 0,
            classIndex = 0, subclassIndex = 0, page = currentPage,
            isUsable = false, qualityIndex = 0, getAll = false
        }
    elseif scanType == AM.Constants.SCAN_TYPE_SNIPER then
         currentQuery = { -- Sniper always queries page 0 for latest items
            name = "", minLevel = 0, maxLevel = 0, invTypeIndex = 0,
            classIndex = 0, subclassIndex = 0, page = 0, -- Sniper specific
            isUsable = false, qualityIndex = 0, getAll = false
        }
        if scanType == AM.Constants.SCAN_TYPE_SNIPER then
             AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Sniper scan querying page 0.")
        end
    end
    
    -- Update progress (totalPages might be 0 on the first call)
    local progress = 0
    if totalPages > 0 then
        -- currentPage is 0-indexed, so add 1 for display
        progress = math.floor(((currentPage + 1) / totalPages) * 100) 
    end
    AM.Events:FireEvent(AM.Constants.EVENTS.SCAN_PROGRESS, progress, currentPage + 1, totalPages)
    
    -- Execute the query with throttling
    local timeSinceLastScan = GetTime() - lastScanTime
    if timeSinceLastScan < (scanThrottle / 1000) then
        C_Timer.After((scanThrottle / 1000) - timeSinceLastScan, function()
            if scanInProgress then -- Re-check scanInProgress in case it was cancelled during the timer
                QueryAuctionItems(
                    currentQuery.name, currentQuery.minLevel, currentQuery.maxLevel,
                    currentQuery.invTypeIndex, currentQuery.classIndex, currentQuery.subclassIndex,
                    currentQuery.page, currentQuery.isUsable, currentQuery.qualityIndex,
                    currentQuery.getAll
                )
                lastScanTime = GetTime()
                AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Querying page " .. currentQuery.page .. " (Throttled)")
            end
        end)
    else
        QueryAuctionItems(
            currentQuery.name, currentQuery.minLevel, currentQuery.maxLevel,
            currentQuery.invTypeIndex, currentQuery.classIndex, currentQuery.subclassIndex,
            currentQuery.page, currentQuery.isUsable, currentQuery.qualityIndex,
            currentQuery.getAll
        )
        lastScanTime = GetTime()
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Querying page " .. currentQuery.page .. " (Immediate)")
    end
end

-- Handle auction data updates (AUCTION_ITEM_LIST_UPDATE event)
function Scanner:OnAuctionUpdate()
    if not scanInProgress then return end
    
    self:ProcessCurrentPage() -- Process results for the page that was just queried (currentPage)
    
    local numBatchAuctions, totalAuctions = GetNumAuctionItems("list")
    
    -- Determine total pages on the first page of results for non-sniper scans
    if currentPage == 0 and scanType ~= AM.Constants.SCAN_TYPE_SNIPER then
        if totalAuctions == 0 then
            totalPages = 1 -- No items, scan is effectively done after this one page result
        else
            if numBatchAuctions > 0 then
                totalPages = math.ceil(totalAuctions / numBatchAuctions)
            else
                -- This case (numBatchAuctions is 0 but totalAuctions > 0) should ideally not happen.
                -- If it does, it implies an issue with AH data. Treat as one page to prevent errors.
                totalPages = 1 
                AM.Util.Debug(AM.Constants.DEBUG_LEVEL.WARNING, "Warning: numBatchAuctions is 0 but totalAuctions > 0. Setting totalPages to 1.")
            end
        end
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Scan update. Total items: " .. totalAuctions .. ". Total pages calculated: " .. totalPages)
    elseif scanType == AM.Constants.SCAN_TYPE_SNIPER then
        totalPages = 1 -- Sniper scan is always considered a single page (the most recent items)
    end

    -- Check if scan should continue
    -- currentPage is 0-indexed. If totalPages is 5, the last page index is 4.
    -- So, continue if currentPage < (totalPages - 1)
    if currentPage < totalPages - 1 then 
        currentPage = currentPage + 1
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Proceeding to next page: " .. currentPage .. " of " .. totalPages -1 .. " (0-indexed)")
        self:QueryCurrentPage()
    else
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "All pages scanned or single page scan complete. Current page: " .. currentPage .. ", Total pages: " .. totalPages)
        self:EndScan()
    end
end

-- Process the current page of auction results
function Scanner:ProcessCurrentPage()
    local numBatchAuctions = GetNumAuctionItems("list")
    
    -- Process each auction
    for i = 1, numBatchAuctions do
        local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, 
              bidAmount, highBidder, owner, saleStatus = GetAuctionItemInfo("list", i)
        
        -- Skip if no name (shouldn't happen, but just in case)
        if name then
            local itemLink = GetAuctionItemLink("list", i)
            local timeLeft = GetAuctionItemTimeLeft("list", i)
            
            -- Get item key
            local itemKey = AM.Util.GetItemKey(itemLink)
            
            if itemKey then
                -- Create auction data
                local auction = {
                    name = name,
                    texture = texture,
                    count = count,
                    quality = quality,
                    level = level,
                    minBid = minBid,
                    bidAmount = bidAmount,
                    buyout = buyoutPrice,
                    owner = owner,
                    timeLeft = timeLeft,
                    itemLink = itemLink,
                    timestamp = GetTime()
                }
                
                -- Add to results
                if not scanResults[itemKey] then
                    scanResults[itemKey] = {}
                end
                
                table.insert(scanResults[itemKey], auction)
            end
        end
    end
end

-- End the current scan
function Scanner:EndScan(errorMsg)
    -- Check if scan was in progress
    if not scanInProgress then return end
    
    -- Calculate scan duration
    local scanDuration = GetTime() - scanStartTime
    
    -- Update scan status
    scanInProgress = false
    
    -- Process results
    if not errorMsg then
        -- Count total items scanned
        local totalItems = 0
        for itemKey, auctions in pairs(scanResults) do
            totalItems = totalItems + #auctions
            
            -- Save auction data to database
            AM.DB:SaveAuctionData(itemKey, auctions)
        end
        
        -- Update scan statistics
        local realmData = AM.DB.realm
        realmData.scanStats.totalScans = (realmData.scanStats.totalScans or 0) + 1
        realmData.scanStats.lastFullScan = GetTime()
        
        -- Update average scan time
        if realmData.scanStats.averageScanTime and realmData.scanStats.averageScanTime > 0 then
            realmData.scanStats.averageScanTime = (realmData.scanStats.averageScanTime * 0.8) + (scanDuration * 0.2)
        else
            realmData.scanStats.averageScanTime = scanDuration
        end
        
        -- Update last scan time
        realmData.lastScan = GetTime()
        
        -- Cache search results if this was a search
        if scanType == AM.Constants.SCAN_TYPE_TARGETED and currentQuery.searchTerm then
            local cacheKey = currentQuery.searchTerm:lower()
            searchCache[cacheKey] = {
                time = GetTime(),
                results = scanResults
            }
        end
        
        -- Fire scan complete event
        AM.Events:FireEvent(AM.Constants.EVENTS.SCAN_COMPLETE, scanResults, totalItems, scanDuration)
        
        -- Print completion message
        print("|cFF00CCFF" .. L:Get("SCAN_COMPLETE", totalItems) .. "|r")
    else
        -- Fire scan failed event
        AM.Events:FireEvent(AM.Constants.EVENTS.SCAN_FAILED, errorMsg)
        
        -- Print error message
        print("|cFFFF0000" .. L:Get(errorMsg) .. "|r")
    end
    
    -- Clear scan data
    scanResults = {}
    currentQuery = {}
    currentPage = 0
    totalPages = 0
end

-- Handle auction house closed
function Scanner:OnAuctionHouseClosed()
    -- End any in-progress scan
    if scanInProgress then
        self:EndScan("ERROR_AH_CLOSED")
    end
end

-- Check if a scan is in progress
function Scanner:IsScanning()
    return scanInProgress
end

-- Get the current scan progress
function Scanner:GetScanProgress()
    if not scanInProgress then
        return 100
    end
    
    if totalPages == 0 then
        return 0
    end
    
    return math.floor((currentPage / totalPages) * 100)
end

-- Get the last scan results
function Scanner:GetLastScanResults()
    return scanResults
end
