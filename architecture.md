# AuctionMaster: Architecture Design

This document outlines the architecture for AuctionMaster, a powerful yet user-friendly auction house addon for WoW 3.3.5a. The architecture is designed to support all the core features while maintaining performance and extensibility.

## Overall Architecture

AuctionMaster follows a modular architecture with clear separation of concerns:

### Core Components

1. **Core Module**
   - Addon initialization and event handling
   - API registration and management
   - Module loading and dependency management
   - Global settings and configuration

2. **Data Layer**
   - Database management for auction data
   - Data compression and storage optimization
   - Historical price tracking
   - Data import/export functionality
   - Caching system for frequently accessed data

3. **Scanning Engine**
   - Auction house query management
   - Incremental scanning algorithms
   - Background processing of scan results
   - Scan scheduling and throttling
   - Data normalization and validation

4. **Price Engine**
   - Price calculation algorithms
   - Market trend analysis
   - Statistical processing of auction data
   - Custom price sources
   - Price history management

5. **UI Framework**
   - Custom UI elements and templates
   - Frame management and positioning
   - Theme management
   - Animation and visual effects
   - Responsive layout system

6. **Tooltip System**
   - Tooltip hook management
   - Dynamic tooltip content generation
   - Tooltip formatting and styling
   - Performance optimization for tooltips

7. **Auction Management**
   - Posting interface and logic
   - Auction monitoring
   - Cancel/repost functionality
   - Batch operations

8. **Shopping System**
   - Shopping list management
   - Sniper functionality
   - Deal detection algorithms
   - Purchase tracking

9. **Utility Services**
   - Logging and debugging
   - Performance monitoring
   - Error handling
   - Communication between modules

## Module Dependencies

```
Core Module
├── Data Layer
├── UI Framework
│   ├── Tooltip System
│   ├── Auction Management UI
│   └── Shopping System UI
├── Scanning Engine
│   └── Data Layer
├── Price Engine
│   ├── Data Layer
│   └── Scanning Engine
├── Auction Management
│   ├── Price Engine
│   └── Data Layer
└── Shopping System
    ├── Price Engine
    └── Data Layer
```

## External Dependencies

AuctionMaster will utilize the following libraries:

- **LibStub**: For library versioning and management
- **LibExtraTip**: For tooltip enhancement
- **LibCompress**: For data compression
- **LibParse**: For data parsing and manipulation
- **LibDataBroker**: For minimap button and data sharing

## Data Flow

1. **Scanning Process**:
   - User initiates scan or scheduled scan triggers
   - Scanning Engine sends queries to auction house API
   - Raw data is processed and normalized
   - Processed data is passed to Data Layer for storage
   - Price Engine analyzes new data and updates price metrics
   - UI is updated with scan progress and results

2. **Tooltip Display**:
   - Game generates tooltip for an item
   - Tooltip System intercepts via hooks
   - Price data is requested from Price Engine
   - Data Layer provides historical information
   - Tooltip is enhanced with formatted price data
   - Enhanced tooltip is displayed to user

3. **Auction Posting**:
   - User selects item to post
   - Auction Management requests current market data
   - Price Engine provides pricing recommendations
   - User confirms or adjusts pricing
   - Auction Management submits to auction house API
   - Data Layer records the posting

4. **Shopping Process**:
   - Shopping System monitors auction house for items on lists
   - Scanning Engine provides new auction data
   - Price Engine evaluates deals based on thresholds
   - User is alerted of potential deals
   - Purchase actions are recorded in Data Layer

## Performance Considerations

1. **Memory Management**:
   - Lazy loading of non-essential modules
   - Data pruning for historical records
   - Efficient data structures for auction storage
   - Memory usage monitoring

2. **CPU Optimization**:
   - Throttled scanning to prevent UI freezes
   - Background processing for intensive operations
   - Caching of frequently accessed data
   - Deferred processing of non-critical tasks

3. **SavedVariables Optimization**:
   - Data compression for large datasets
   - Selective storage of essential data only
   - Configurable data retention policies
   - Efficient serialization/deserialization

## Extensibility

The architecture supports future extensions through:

1. **Plugin System**:
   - Hooks for third-party addons
   - Event system for inter-module communication
   - Public API for accessing price data

2. **Module System**:
   - Self-contained modules with clear interfaces
   - Dependency injection for module communication
   - Versioned API for backward compatibility

3. **Configuration System**:
   - Profile-based settings
   - Feature toggles for enabling/disabling functionality
   - Performance tuning options

This architecture provides a solid foundation for implementing all the planned features while maintaining performance and usability.
