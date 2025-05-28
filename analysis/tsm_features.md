# TradeSkillMaster Features Analysis

TradeSkillMaster (TSM) is a comprehensive auction house and crafting addon with extensive features. This analysis focuses on its auction house functionality that could be relevant for our AuctionMaster addon.

## Core Auction House Features

TradeSkillMaster provides a robust set of auction house tools that significantly enhance the default UI. The most notable features include:

- Advanced auction scanning system that collects comprehensive market data
- Sophisticated price calculation algorithms (market value, historical value, etc.)
- Detailed tooltips showing various price points and profit margins
- Sniper functionality for finding deals on newly posted auctions
- Batch posting of multiple items with customizable rules
- Customizable shopping searches with saved filters
- Auction operation system for applying consistent settings to groups of items
- Comprehensive item grouping system for organization
- Price source system that allows for complex pricing formulas

## Implementation Approach

TSM uses a modular architecture with several key components:

- Core API (TSMAPI) that provides functionality to all modules
- Extensive use of LibStub for library management
- Custom UI framework for consistent styling
- Advanced data structures for efficient storage and retrieval
- Background processing for handling large datasets without freezing the UI
- Caching mechanisms to improve performance
- Custom scrolling tables for displaying large amounts of data

## Performance Considerations

While TSM is feature-rich, it comes with performance implications:

- High memory usage due to extensive data storage
- Complex calculations can cause momentary UI freezes
- Large saved variable files that can impact loading times
- Multiple background processes that can affect overall game performance
- Complex codebase that can be difficult to maintain and extend

## UI Elements

TSM's UI is comprehensive but can be overwhelming:

- Custom auction house frame that replaces the default UI
- Multiple tabs for different functionality
- Custom scrolling tables with sortable columns
- Advanced filter options
- Price input fields with smart formatting
- Progress bars for scan operations
- Custom tooltips with extensive information

## Potential Improvements for AuctionMaster

Based on TSM's approach, we can identify several areas for improvement:

- Simplify the UI while maintaining powerful functionality
- Focus on auction house features without the crafting complexity
- Improve performance by optimizing data structures and processing
- Provide more intuitive controls for common auction house tasks
- Balance between feature richness and ease of use
- Implement efficient scanning that doesn't overwhelm the server or client
