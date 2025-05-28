# Auction House API Analysis

## Core Blizzard API Functions

From analyzing the Blizzard_AuctionUI.lua file, these are the key API functions available for auction house addons:

### Auction Browsing
- `QueryAuctionItems(name, minLevel, maxLevel, invTypeIndex, classIndex, subclassIndex, page, isUsable, qualityIndex, getAll)` - Search the auction house
- `GetNumAuctionItems(type)` - Get number of auctions (type can be "list", "bidder", "owner")
- `GetAuctionItemInfo(type, index)` - Get information about an auction item
- `GetAuctionItemLink(type, index)` - Get item link for an auction item
- `GetSelectedAuctionItem(type)` - Get currently selected auction
- `PlaceAuctionBid(type, index, bidAmount)` - Place a bid on an auction

### Auction Selling
- `PostAuction(minBid, buyoutPrice, runTime, stackSize, numStacks)` - Post an auction
- `CalculateAuctionDeposit(runTime)` - Calculate deposit cost
- `CancelAuction(index)` - Cancel an auction

### Auction Data
- `GetAuctionItemClasses()` - Get item categories
- `GetAuctionItemSubClasses(classIndex)` - Get item subcategories
- `GetAuctionInvTypes(classIndex, subclassIndex)` - Get inventory types

## Constants and Limitations
- `NUM_AUCTION_ITEMS_PER_PAGE = 50` - Maximum items per page
- `MAXIMUM_BID_PRICE = 2000000000` - Maximum bid price (2 billion copper)
- Auction durations are fixed at 12, 24, and 48 hours

## Performance Considerations
- `GetAll` scan is limited and throttled
- Scanning the entire auction house requires paginated queries
- Processing large datasets can cause UI freezes if not handled properly
