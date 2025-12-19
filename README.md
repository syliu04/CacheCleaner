# Cache Cleaner

A lightweight macOS application that helps you clean system caches, user caches, log files, and empty trash to free up disk space.

## Table of Contents

- [For Users](#installation-for-end-users) - Download and install the app
- [For Developers](#for-developers) - Build and develop the app

## Features

- **Selective Cache Cleaning**: Choose which caches to clean
  - User Cache (`~/Library/Caches`)
  - System Cache (`/Library/Caches`) - requires admin privileges
  - Log Files (`~/Library/Logs`)
  - Trash (`~/.Trash`)
- **Calculate Before Cleaning**: See how much space each cache type is using before cleaning
- **Safe Cleaning**: Automatically skips protected system files

## Prerequisites

- macOS 12.0 (Monterey) or later

## Installation for End Users

### Download the App

1. **Download the DMG file** from the [Releases page](https://github.com/YOUR-USERNAME/CacheCleaner/releases)
   - Look for the latest release
   - Download the `CacheCleaner-v1.0.dmg` file

2. **Install the app**:
   - Open the downloaded DMG file
   - Drag the Cache Cleaner app to the Applications folder
   - Eject the DMG

3. **Launch the app**:
   - Open Finder → Applications
   - Double-click on Cache Cleaner
   - If you see a security warning, go to System Preferences → Security & Privacy → General, and click "Open Anyway"

4. **Grant permissions** (if needed):
   - Go to System Preferences → Security & Privacy → Privacy
   - Select "Full Disk Access"
   - Click the lock and authenticate
   - Add Cache Cleaner to the list

### Using the App

1. Launch Cache Cleaner
2. Select the cache types you want to clean (User Cache, Log Files, Trash)
3. Click "Calculate Size" to see how much space each cache is using (optional)
4. Click "Clean Selected" to remove the selected caches
5. View the results showing how much space was freed

**Important**: Close all other applications before cleaning caches to avoid potential issues.

## Permissions

The app requires certain permissions to access and clean cache directories:

- **Full Disk Access**: You may need to grant Full Disk Access to the app
  - Go to System Preferences → Security & Privacy → Privacy → Full Disk Access
  - Click the lock and authenticate
  - Add Cache Cleaner to the list

---

## For Developers

Complete developer documentation is available in the [`docs/`](docs/) directory:

- **[Development Guide](docs/DEVELOPMENT.md)** - Setup, building, and development workflow
- **[Architecture](docs/ARCHITECTURE.md)** - Code structure and design patterns
- **[Testing Guide](docs/TESTING.md)** - Writing and running tests
- **[Contributing](docs/CONTRIBUTING.md)** - How to contribute to the project

### Quick Start for Developers

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/CacheCleaner.git
cd CacheCleaner

# Open in Xcode
open CacheCleaner.xcodeproj

# Run tests
xcodebuild test -project CacheCleaner.xcodeproj -scheme CacheCleaner

# Build Release version
xcodebuild -project CacheCleaner.xcodeproj \
           -scheme CacheCleaner \
           -configuration Release \
           -derivedDataPath ./build \
           build
```

### Project Structure

```
CacheCleaner/
├── CacheCleaner/                    # Main application source
│   ├── Assets.xcassets/             # App icons and assets
│   │   └── AppIcon.appiconset/      # All icon sizes (16-1024px)
│   ├── CacheCleanerApp.swift        # App entry point
│   └── ContentView.swift            # Main UI and logic
├── CacheCleanerTests/               # Test suite
│   ├── CacheCleanerTests.swift      # Unit tests
│   └── IntegrationTests.swift       # Integration tests
├── docs/                            # Developer documentation
│   ├── ARCHITECTURE.md              # Architecture documentation
│   ├── CONTRIBUTING.md              # Contributing guidelines
│   ├── DEVELOPMENT.md               # Development guide
│   └── TESTING.md                   # Testing guide
├── CacheCleaner.xcodeproj/          # Xcode project
├── .gitignore                       # Git ignore rules
├── create-dmg.sh                    # Automated DMG creation script
├── CacheCleaner-v1.0.dmg           # Distribution DMG
└── README.md                        # This file
```

---

## Safety Notes

- The app automatically skips Apple system files and protected directories
- Cache cleaning is generally safe, but close other apps first
- The app won't delete files it doesn't have permission to access
- System caches are automatically skipped to prevent system issues

## Troubleshooting

### Permission Denied Errors

If you see permission errors when cleaning caches:
1. Go to System Preferences → Security & Privacy → Privacy
2. Select "Full Disk Access"
3. Click the lock and authenticate
4. Add the CacheCleaner app to the list

### App Security Warning

If you see a security warning when opening the app:
- Go to System Preferences → Security & Privacy → General
- Click "Open Anyway" next to the Cache Cleaner warning

## Contributing

Contributions are welcome! Please read the [Contributing Guidelines](docs/CONTRIBUTING.md) before submitting pull requests.

## License

This project is available for personal and educational use.

## Author

ShengYao Liu

---

**Note**: This app is designed for macOS only and requires a Mac to build and run.

For detailed development instructions, architecture information, and testing guides, see the [documentation](docs/).
