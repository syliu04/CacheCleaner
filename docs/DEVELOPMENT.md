# Cache Cleaner - Development Guide

Complete guide for developers working on the Cache Cleaner macOS application.

## Table of Contents

- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Development Environment](#development-environment)
- [Building the Project](#building-the-project)
- [Running Tests](#running-tests)
- [Code Style](#code-style)
- [Common Development Tasks](#common-development-tasks)

## Project Structure

```
CacheCleaner/
├── CacheCleaner/                    # Main application source code
│   ├── Assets.xcassets/             # App icons and assets
│   │   └── AppIcon.appiconset/      # All icon sizes (16x16 to 1024x1024)
│   │       ├── icon_16x16.png       # 16pt @1x
│   │       ├── icon_32x32.png       # 16pt @2x, 32pt @1x
│   │       ├── icon_64x64.png       # 32pt @2x
│   │       ├── icon_128x128.png     # 128pt @1x
│   │       ├── icon_256x256.png     # 128pt @2x, 256pt @1x
│   │       ├── icon_512x512.png     # 256pt @2x, 512pt @1x
│   │       ├── icon_1024x1024.png   # 512pt @2x
│   │       └── Contents.json        # Icon manifest
│   ├── CacheCleanerApp.swift        # App entry point and window configuration
│   └── ContentView.swift            # Main UI and cache cleaning logic
├── CacheCleanerTests/               # Unit and integration tests
│   ├── CacheCleanerTests.swift      # Unit tests
│   └── IntegrationTests.swift       # Integration tests
├── docs/                            # Developer documentation
│   ├── ARCHITECTURE.md              # Architecture documentation
│   ├── CONTRIBUTING.md              # Contribution guidelines
│   ├── DEVELOPMENT.md               # This file
│   └── TESTING.md                   # Testing guide
├── CacheCleaner.xcodeproj/          # Xcode project configuration
├── .gitignore                       # Git ignore rules
├── create-dmg.sh                    # Automated DMG creation script
├── CacheCleaner-v1.0.dmg           # Distribution DMG file
└── README.md                        # User-facing documentation
```

## Getting Started

### Prerequisites

- **macOS**: Version 12.0 (Monterey) or later
- **Xcode**: Version 14.0 or later
- **Command Line Tools**: Xcode Command Line Tools installed

### Initial Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/syliu04/CacheCleaner.git
   cd CacheCleaner
   ```

2. **Open in Xcode**:
   ```bash
   open CacheCleaner.xcodeproj
   ```

3. **Verify Xcode configuration**:
   ```bash
   xcode-select -p
   # Should output: /Applications/Xcode.app/Contents/Developer
   ```

4. **Build and run**:
   - Press `Cmd + R` or click the Play button
   - Select "My Mac" as the run destination

## Development Environment

### Xcode Setup

1. **Open the project**: `open CacheCleaner.xcodeproj`

2. **Configure signing**:
   - Select the project in the navigator
   - Go to Signing & Capabilities
   - Select your development team
   - Xcode will automatically manage signing

3. **Enable Full Disk Access** (for testing):
   - Go to System Preferences → Security & Privacy → Privacy
   - Select "Full Disk Access"
   - Add Xcode to the list

### VS Code Setup

While Xcode is recommended, you can also use VS Code:

1. **Install Swift extension**: Search for "Swift" in VS Code extensions

2. **Build from terminal**:
   ```bash
   xcodebuild -project CacheCleaner.xcodeproj -scheme CacheCleaner -configuration Debug build
   ```

3. **Run the app**:
   ```bash
   open ~/Library/Developer/Xcode/DerivedData/CacheCleaner-*/Build/Products/Debug/CacheCleaner.app
   ```

## Building the Project

### Debug Build

```bash
xcodebuild -project CacheCleaner.xcodeproj \
           -scheme CacheCleaner \
           -configuration Debug \
           build
```

### Release Build

```bash
xcodebuild -project CacheCleaner.xcodeproj \
           -scheme CacheCleaner \
           -configuration Release \
           -derivedDataPath ./build \
           build
```

The Release build will be at: `./build/Build/Products/Release/CacheCleaner.app`

### Creating a DMG

Use the automated DMG creation script for best results:

```bash
# Build Release version first
xcodebuild -project CacheCleaner.xcodeproj \
           -scheme CacheCleaner \
           -configuration Release \
           -derivedDataPath ./build \
           build

# Create DMG with visual instructions
./create-dmg.sh
```

The `create-dmg.sh` script automatically:
- Creates a properly formatted DMG
- Adds visual installation instructions
- Positions icons correctly
- Creates an Applications folder shortcut
- Adds a background image with arrows
- Compresses the DMG for distribution

**Manual DMG creation** (if needed):

```bash
mkdir -p ./dmg-build
cp -R ./build/Build/Products/Release/CacheCleaner.app ./dmg-build/
ln -s /Applications ./dmg-build/Applications
hdiutil create -volname "Cache Cleaner" \
               -srcfolder ./dmg-build \
               -ov \
               -format UDZO \
               CacheCleaner-v1.0.dmg
rm -rf ./dmg-build
```

## Running Tests

### Run all tests in Xcode

```bash
xcodebuild test -project CacheCleaner.xcodeproj -scheme CacheCleaner
```

### Run specific test class

```bash
xcodebuild test -project CacheCleaner.xcodeproj \
                -scheme CacheCleaner \
                -only-testing:CacheCleanerTests/CacheCleanerTests
```

### Run specific test method

```bash
xcodebuild test -project CacheCleaner.xcodeproj \
                -scheme CacheCleaner \
                -only-testing:CacheCleanerTests/CacheCleanerTests/testGetDirectorySize_WithFiles
```

### Generate code coverage

```bash
xcodebuild test -project CacheCleaner.xcodeproj \
                -scheme CacheCleaner \
                -enableCodeCoverage YES
```

## Code Style

### Swift Style Guide

Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/):

- Use `camelCase` for functions and variables
- Use `PascalCase` for types and protocols
- Prefer `let` over `var` when possible
- Use descriptive names

**Example**:
```swift
// Good
func calculateCacheSize() -> Int64 { }
let totalCacheSize: String = "0 MB"

// Avoid
func calc() -> Int64 { }
var x: String = "0 MB"
```

### SwiftUI Conventions

- Keep views small and focused
- Extract complex views into separate structs
- Use `@State` for view-local state
- Use descriptive view names ending in `View`

**Example**:
```swift
struct CacheSelectionRow: View {
    let cacheType: CacheType
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        // View implementation
    }
}
```

### File Organization

- Group related functionality with `// MARK: - Section Name`
- Keep files under 500 lines when possible
- One type per file (except for small helper types)

## Common Development Tasks

### Adding a New Cache Type

1. **Update the enum** in `ContentView.swift`:
   ```swift
   enum CacheType: String, CaseIterable, Hashable {
       case userCache = "User Cache"
       case systemCache = "System Cache"
       case logs = "Log Files"
       case trash = "Empty Trash"
       case newCache = "New Cache Type"  // Add here

       var path: String {
           switch self {
           // ... existing cases ...
           case .newCache:
               return "/path/to/new/cache"
           }
       }
   }
   ```

2. **Add icon** in `CacheSelectionRow`:
   ```swift
   private func icon(for cacheType: ContentView.CacheType) -> String {
       switch cacheType {
       // ... existing cases ...
       case .newCache: return "folder.fill"
       }
   }
   ```

3. **Write tests** in `CacheCleanerTests.swift`:
   ```swift
   func testCachePaths_NewCache() {
       // Test implementation
   }
   ```

### Modifying the UI

1. **Main layout** is in `ContentView.swift` `body` property
2. **Custom views** are at the bottom of the file under `// MARK: - Custom Views`
3. **Animations** use SwiftUI's `.animation()` and `.transition()` modifiers
4. **Colors** use gradient definitions inline

### Updating the App Icon

1. **Generate new icons**: Use Python script or create manually
2. **Place in Assets.xcassets**: `CacheCleaner/Assets.xcassets/AppIcon.appiconset/`
3. **Update Contents.json**: Reference all icon sizes
4. **Required sizes**: 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024

### Debugging

1. **Enable debug output**: Look for `print("DEBUG: ...")` statements
2. **Check file paths**: Logs show actual paths being used
3. **Verify permissions**: Check System Preferences → Security & Privacy
4. **Use Xcode debugger**: Set breakpoints in key functions

### Performance Optimization

1. **Use background threads**: Cache operations run on `.background` queue
2. **Avoid main thread blocking**: Update UI on main thread only
3. **Test with large directories**: Use performance tests
4. **Profile in Instruments**: Use Xcode's Instruments for detailed analysis

## Troubleshooting

### Build Fails

**Error**: "xcodebuild requires Xcode"
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

**Error**: Code signing issues
- Go to Xcode → Preferences → Accounts
- Add your Apple ID
- Select the project → Signing & Capabilities → Team

### Tests Fail

**Error**: File system permission denied
- Grant Full Disk Access to the test runner
- Tests create temporary directories that may need permissions

**Error**: Tests timeout
- Increase timeout in test expectations
- Check for deadlocks in async operations

### Runtime Issues

**Error**: App can't access cache directories
- Grant Full Disk Access: System Preferences → Security & Privacy
- Check that paths are correctly resolved

**Error**: App crashes on launch
- Check Console.app for crash logs
- Look for `CacheCleaner` process logs
- Verify all required frameworks are linked

## Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Swift.org Documentation](https://swift.org/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Testing in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)

## Next Steps

- Read [ARCHITECTURE.md](ARCHITECTURE.md) for code structure details
- Read [TESTING.md](TESTING.md) for comprehensive testing guide
- Read [CONTRIBUTING.md](CONTRIBUTING.md) before making changes
