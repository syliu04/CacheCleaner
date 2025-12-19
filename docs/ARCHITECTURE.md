# Cache Cleaner - Architecture Documentation

Comprehensive architecture and design documentation for the Cache Cleaner application.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Application Architecture](#application-architecture)
- [Data Flow](#data-flow)
- [Key Components](#key-components)
- [Design Patterns](#design-patterns)
- [File System Operations](#file-system-operations)
- [UI Architecture](#ui-architecture)
- [State Management](#state-management)

## Overview

Cache Cleaner is a native macOS application built with SwiftUI that provides selective cache cleaning capabilities. The application follows a simple, single-view architecture with clear separation between UI and business logic.

### Technology Stack

- **Language**: Swift 5.0+
- **UI Framework**: SwiftUI
- **Minimum macOS**: 12.0 (Monterey)
- **Architecture**: MVVM (Model-View-ViewModel pattern implied in SwiftUI)
- **Testing**: XCTest framework

## Project Structure

```
CacheCleaner/
├── CacheCleaner/                    # Main application
│   ├── Assets.xcassets/             # Visual assets
│   │   └── AppIcon.appiconset/      # App icon in all required sizes
│   │       ├── icon_16x16.png       # 16pt @1x
│   │       ├── icon_32x32.png       # 16pt @2x, 32pt @1x
│   │       ├── icon_64x64.png       # 32pt @2x
│   │       ├── icon_128x128.png     # 128pt @1x
│   │       ├── icon_256x256.png     # 128pt @2x, 256pt @1x
│   │       ├── icon_512x512.png     # 256pt @2x, 512pt @1x
│   │       ├── icon_1024x1024.png   # 512pt @2x
│   │       └── Contents.json        # Icon manifest
│   ├── CacheCleanerApp.swift        # App entry point
│   └── ContentView.swift            # Main view and logic
├── CacheCleanerTests/               # Test suite
│   ├── CacheCleanerTests.swift      # Unit tests
│   └── IntegrationTests.swift       # Integration tests
├── docs/                            # Developer documentation
│   ├── ARCHITECTURE.md              # This file
│   ├── CONTRIBUTING.md              # Contributing guidelines
│   ├── DEVELOPMENT.md               # Development guide
│   └── TESTING.md                   # Testing guide
├── CacheCleaner.xcodeproj/          # Xcode project
├── .gitignore                       # Git ignore rules
├── create-dmg.sh                    # Automated DMG creation script
├── CacheCleaner-v1.0.dmg           # Distribution DMG
└── README.md                        # User documentation
```

## Application Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────┐
│         CacheCleanerApp                 │
│         (@main entry point)             │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│           ContentView                   │
│     (Main UI + Business Logic)          │
│                                         │
│  ┌────────────────────────────────┐    │
│  │    State Management            │    │
│  │  - @State variables            │    │
│  │  - Cache selection             │    │
│  │  - Processing state            │    │
│  └────────────────────────────────┘    │
│                                         │
│  ┌────────────────────────────────┐    │
│  │    Business Logic              │    │
│  │  - calculateCacheSize()        │    │
│  │  - cleanCaches()               │    │
│  │  - getDirectorySize()          │    │
│  │  - clearDirectory()            │    │
│  └────────────────────────────────┘    │
│                                         │
│  ┌────────────────────────────────┐    │
│  │    UI Components               │    │
│  │  - CacheSelectionRow           │    │
│  │  - Gradient backgrounds        │    │
│  │  - Buttons and animations      │    │
│  └────────────────────────────────┘    │
└─────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         File System                     │
│    (FileManager operations)             │
└─────────────────────────────────────────┘
```

## Data Flow

### User Action Flow

```
User selects cache types
        │
        ▼
User clicks "Calculate Size"
        │
        ▼
calculateCacheSize() triggered
        │
        ├──> Set isProcessing = true
        ├──> Dispatch to background thread
        │         │
        │         ├──> For each selected cache:
        │         │     └──> getDirectorySize()
        │         │           └──> Recursive file scan
        │         │                 └──> Sum file sizes
        │         │
        │         └──> Return total size
        │
        ├──> Update UI on main thread
        │     ├──> totalCacheSize = formatted size
        │     └──> cacheBreakdown = individual sizes
        │
        └──> Set isProcessing = false
```

### Cache Cleaning Flow

```
User clicks "Clean Now"
        │
        ▼
cleanCaches() triggered
        │
        ├──> Set isProcessing = true
        ├──> Dispatch to background thread
        │         │
        │         ├──> For each selected cache:
        │         │     ├──> Skip if system cache
        │         │     ├──> Get size before cleaning
        │         │     ├──> clearDirectory()
        │         │     │     └──> Recursive file deletion
        │         │     │           └──> Skip protected files
        │         │     ├──> Get size after cleaning
        │         │     └──> Calculate space freed
        │         │
        │         └──> Sum total space freed
        │
        ├──> Update UI on main thread
        │     ├──> spaceSaved = formatted size
        │     ├──> hasCleaned = true
        │     └──> Trigger success animation
        │
        └──> Set isProcessing = false
```

## Key Components

### 1. CacheCleanerApp.swift

**Purpose**: Application entry point

```swift
@main
struct CacheCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
```

**Responsibilities**:
- Define app lifecycle
- Configure window properties
- Set initial view (ContentView)

### 2. ContentView.swift

**Purpose**: Main view containing UI and business logic

#### State Variables

```swift
@State private var statusMessage: String         // Current status text
@State private var isProcessing: Bool            // Processing indicator
@State private var spaceSaved: String            // Amount of space freed
@State private var totalCacheSize: String        // Total cache size
@State private var cacheBreakdown: [CacheType: String]  // Individual sizes
@State private var hasCalculated: Bool           // Calculation complete flag
@State private var hasCleaned: Bool              // Cleaning complete flag
@State private var selectedCaches: Set<CacheType>  // Selected cache types
@State private var showSuccess: Bool             // Success animation flag
@State private var pulseAnimation: Bool          // Icon animation flag
```

#### CacheType Enum

```swift
enum CacheType: String, CaseIterable, Hashable {
    case userCache = "User Cache"
    case systemCache = "System Cache"
    case logs = "Log Files"
    case trash = "Empty Trash"

    var path: String {
        // Returns the file system path for each cache type
    }
}
```

**Design Decision**: Uses `CaseIterable` for easy iteration and `Hashable` for Set membership.

#### Core Functions

1. **calculateCacheSize()**
   - Runs on background thread
   - Calculates size of each selected cache
   - Updates UI with results on main thread

2. **cleanCaches()**
   - Runs on background thread
   - Cleans each selected cache (except system cache)
   - Tracks space freed
   - Updates UI with success message

3. **getDirectorySize(path: String) -> Int64**
   - Recursively scans directory
   - Sums file sizes
   - Handles permissions gracefully

4. **clearDirectory(at: String)**
   - Deletes files in directory
   - Skips protected Apple system files
   - Preserves directory structure

5. **isProtectedFile(filename: String) -> Bool**
   - Identifies Apple system files
   - Prevents deletion of critical files

### 3. CacheSelectionRow

**Purpose**: Custom view for cache type selection

```swift
struct CacheSelectionRow: View {
    let cacheType: ContentView.CacheType
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        // Custom checkbox UI with animations
    }
}
```

**Features**:
- Custom checkbox design
- Smooth selection animations
- Cache-type specific icons
- Tap gesture handling

## Design Patterns

### 1. Observer Pattern (via SwiftUI)

SwiftUI's `@State` and data binding implement the Observer pattern:

```swift
@State private var selectedCaches: Set<CacheType>

// View automatically updates when selectedCaches changes
ForEach(CacheType.allCases, id: \.self) { cacheType in
    CacheSelectionRow(
        isSelected: selectedCaches.contains(cacheType),
        onToggle: { toggleSelection(for: cacheType) }
    )
}
```

### 2. Strategy Pattern (Implicit)

Different cache types use different path resolution strategies:

```swift
var path: String {
    switch self {
    case .userCache:
        return getRealUserPath() + "/Library/Caches"
    case .systemCache:
        return "/Library/Caches"
    // ... etc
    }
}
```

### 3. Command Pattern

Actions are encapsulated in functions:

```swift
Button(action: { calculateCacheSize() })
Button(action: { cleanCaches() })
```

### 4. Template Method Pattern

Directory operations follow a template:

1. Get size before operation
2. Perform operation
3. Get size after operation
4. Calculate difference

## File System Operations

### Path Resolution

**Challenge**: macOS sandbox may provide virtualized paths

**Solution**: Use `getRealUserPath()` to resolve actual user home directory

```swift
static func getRealUserPath() -> String? {
    guard let pw = getpwuid(getuid()) else { return nil }
    return String(cString: pw.pointee.pw_dir)
}
```

### Protected File Detection

Prevents deletion of critical system files:

```swift
private func isProtectedFile(filename: String) -> Bool {
    let protectedPrefixes = ["com.apple.", "."]
    return protectedPrefixes.contains { filename.hasPrefix($0) }
}
```

### Size Calculation

Uses file system attributes for accurate sizing:

```swift
private func getDirectorySize(path: String) -> Int64 {
    let resourceKeys: Set<URLResourceKey> = [
        .isRegularFileKey,
        .fileAllocatedSizeKey,
        .totalFileAllocatedSizeKey
    ]
    // Enumerate files and sum sizes
}
```

## UI Architecture

### View Hierarchy

```
ContentView
├── ZStack
│   ├── LinearGradient (Background)
│   └── ScrollView
│       └── VStack
│           ├── Title (HStack)
│           ├── Cache Selection Card (VStack)
│           │   └── ForEach → CacheSelectionRow
│           ├── ProgressView (conditional)
│           ├── Status Message (Text)
│           ├── Cache Breakdown (conditional VStack)
│           ├── Success Card (conditional VStack)
│           ├── Action Buttons (HStack)
│           └── Warning (HStack)
```

### Animations

1. **Background Gradient**: Changes from blue to green on completion
2. **Icon Rotation**: Continuous rotation on app load
3. **Success Animation**: Spring animation when cleaning completes
4. **Transitions**: Scale and opacity for appearing/disappearing views

## State Management

### State Flow

```
User Input → @State Update → View Re-render → UI Update
     ↑                                           │
     └───────────── User Sees Change ────────────┘
```

### State Variables Lifecycle

1. **Initial State**: All flags false, empty collections
2. **Selection State**: `selectedCaches` updated
3. **Processing State**: `isProcessing = true`
4. **Calculation State**: `hasCalculated = true`, `cacheBreakdown` populated
5. **Cleaning State**: `hasCleaned = true`, `showSuccess = true`
6. **Reset**: User can calculate/clean again

## Performance Considerations

### Background Threading

All heavy operations run on background threads:

```swift
DispatchQueue.global(qos: .background).async {
    // Heavy work here
    DispatchQueue.main.async {
        // UI updates here
    }
}
```

### Lazy Loading

Views use conditional rendering to avoid unnecessary work:

```swift
if hasCalculated && !hasCleaned && !cacheBreakdown.isEmpty {
    // Only render breakdown when needed
}
```

### Resource Management

- File handles are automatically managed by FileManager
- Enumerators are properly released after use
- Memory efficient directory traversal (iterator pattern)

## Security Considerations

1. **Sandboxing**: App respects macOS sandbox restrictions
2. **Protected Files**: System files are never deleted
3. **Permissions**: User must grant Full Disk Access
4. **Validation**: Path validation before operations

## Extensibility

### Adding New Cache Types

1. Add case to `CacheType` enum
2. Implement `path` property
3. Add icon mapping
4. Add tests

### Adding New Features

The architecture supports easy addition of:
- New cleaning algorithms
- Additional file type filters
- Custom cleaning rules
- Scheduling capabilities

## Testing Architecture

See [TESTING.md](TESTING.md) for complete testing documentation.

### Test Structure

- **Unit Tests**: Test individual functions in isolation
- **Integration Tests**: Test component interactions
- **Performance Tests**: Measure operation timing

## Dependencies

### System Frameworks

- **SwiftUI**: UI framework
- **Foundation**: Core functionality
- **XCTest**: Testing framework (dev only)

### Third-Party Dependencies

None - the app uses only system frameworks.

## Build Configuration

### Debug vs Release

- **Debug**: Includes debug symbols, no optimization
- **Release**: Optimized, symbols stripped, ready for distribution

### Code Signing

- Development: Self-signed
- Distribution: Requires Apple Developer account

## Future Architecture Considerations

Potential improvements:

1. **MVVM Separation**: Extract business logic to separate ViewModel
2. **Dependency Injection**: Make FileManager injectable for testing
3. **Repository Pattern**: Abstract file system operations
4. **Command Queue**: Queue cleaning operations for undo capability
5. **Plugin System**: Allow custom cache type definitions

---

For implementation details, see [DEVELOPMENT.md](DEVELOPMENT.md).
For testing strategies, see [TESTING.md](TESTING.md).
