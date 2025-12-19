# Contributing to Cache Cleaner

Thank you for your interest in contributing to Cache Cleaner! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)
- [Issue Reporting](#issue-reporting)

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Focus on constructive feedback
- Accept differing viewpoints gracefully
- Prioritize what's best for the community

## Getting Started

### Prerequisites

- macOS 12.0 (Monterey) or later
- Xcode 14.0 or later
- Git installed and configured
- GitHub account

### Fork and Clone

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/CacheCleaner.git
   cd CacheCleaner
   ```

   **Note**: Replace `YOUR-USERNAME` with your GitHub username. The main repository is at [github.com/syliu04/CacheCleaner](https://github.com/syliu04/CacheCleaner).

3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/syliu04/CacheCleaner.git
   ```

4. **Verify remotes**:
   ```bash
   git remote -v
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
│   ├── CONTRIBUTING.md              # This file
│   ├── DEVELOPMENT.md               # Development guide
│   └── TESTING.md                   # Testing guide
├── CacheCleaner.xcodeproj/          # Xcode project
├── .gitignore                       # Git ignore rules
├── create-dmg.sh                    # Automated DMG creation script
├── CacheCleaner-v1.0.dmg           # Distribution DMG
└── README.md                        # User documentation
```

## Development Workflow

### 1. Create a Branch

Create a feature branch from `main`:

```bash
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation
- `test/description` - Test additions/fixes
- `refactor/description` - Code refactoring

### 2. Make Changes

1. **Open in Xcode**:
   ```bash
   open CacheCleaner.xcodeproj
   ```

2. **Make your changes** following [Coding Standards](#coding-standards)

3. **Test your changes**:
   ```bash
   # Run tests
   xcodebuild test -project CacheCleaner.xcodeproj \
                    -scheme CacheCleaner

   # Or in Xcode: Cmd + U
   ```

4. **Build successfully**:
   ```bash
   xcodebuild -project CacheCleaner.xcodeproj \
              -scheme CacheCleaner \
              -configuration Release \
              build
   ```

### 3. Commit Changes

Follow commit message conventions:

```bash
git add .
git commit -m "feat: add cache scheduling feature"
```

Commit message format:

```
<type>: <description>

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions/changes
- `refactor`: Code refactoring
- `style`: Code style changes (formatting)
- `chore`: Maintenance tasks

Examples:

```
feat: add trash emptying functionality

- Add trash cache type to enum
- Implement trash path resolution
- Add icon for trash selection

Closes #123
```

```
fix: prevent deletion of protected Apple files

- Add check for com.apple.* prefix
- Skip .DS_Store files
- Add tests for protected file detection

Fixes #456
```

### 4. Push Changes

```bash
git push origin feature/your-feature-name
```

### 5. Create Pull Request

1. Go to GitHub repository
2. Click "Pull requests" → "New pull request"
3. Select your branch
4. Fill in the PR template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] All tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
```

## Pull Request Process

### Requirements

Before submitting a PR, ensure:

1. **All tests pass**:
   ```bash
   xcodebuild test -project CacheCleaner.xcodeproj \
                    -scheme CacheCleaner
   ```

2. **Code builds successfully**:
   ```bash
   xcodebuild -project CacheCleaner.xcodeproj \
              -scheme CacheCleaner \
              build
   ```

3. **Code coverage** is maintained or improved (>80%)

4. **Documentation** is updated if needed

5. **No merge conflicts** with main branch

### Review Process

1. **Automated checks** run (tests, build)
2. **Code review** by maintainers
3. **Changes requested** (if needed)
4. **Approval** from maintainer(s)
5. **Merge** into main

### Getting Your PR Reviewed

- Keep PRs focused and small
- Respond to feedback promptly
- Update PR based on review comments
- Be patient and respectful

## Coding Standards

### Swift Style Guide

Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/):

#### Naming

```swift
// Good
func calculateTotalCacheSize() -> Int64 { }
let selectedCacheTypes: Set<CacheType>
var isProcessing: Bool

// Avoid
func calc() -> Int64 { }
let x: Set<CacheType>
var flag: Bool
```

#### Layout

```swift
// Use 4 spaces for indentation
func example() {
    if condition {
        doSomething()
    }
}

// Line length: max 120 characters
// Break long lines appropriately
let result = calculateVeryLongFunctionName(
    parameter1: value1,
    parameter2: value2,
    parameter3: value3
)
```

#### Comments

```swift
// Single-line comments for brief explanations

/// Documentation comments for public API
/// - Parameter path: The directory path to scan
/// - Returns: Total size in bytes
func getDirectorySize(path: String) -> Int64 { }

// MARK: - Section Headers
// Use MARK to organize code into sections
```

### SwiftUI Best Practices

1. **Keep views small**:
   ```swift
   // Extract complex views
   struct CacheSelectionRow: View {
       // Focused, reusable view
   }
   ```

2. **Use meaningful names**:
   ```swift
   // Good
   @State private var isCalculatingSize: Bool

   // Avoid
   @State private var flag: Bool
   ```

3. **Organize view body**:
   ```swift
   var body: some View {
       ZStack {
           backgroundView
           contentView
       }
   }

   private var backgroundView: some View {
       // Extracted for clarity
   }
   ```

### File Organization

```swift
// Import statements
import SwiftUI
import Foundation

// MARK: - Main Type

struct ContentView: View {
    // MARK: - Properties

    // MARK: - Body

    // MARK: - Private Methods

    // MARK: - Helper Functions
}

// MARK: - Supporting Types

// MARK: - Extensions
```

## Testing Requirements

### Test Coverage

All contributions must maintain >80% code coverage:

- **New features**: Add unit tests
- **Bug fixes**: Add regression tests
- **Refactoring**: Ensure existing tests pass

### Writing Tests

See [TESTING.md](TESTING.md) for comprehensive testing guide.

Example test:

```swift
func testNewFeature_Scenario_ExpectedBehavior() throws {
    // Given: Setup test conditions
    let testData = createTestData()

    // When: Perform action
    let result = performAction(testData)

    // Then: Verify outcome
    XCTAssertEqual(result, expectedValue)
}
```

### Running Tests

```bash
# All tests
xcodebuild test -project CacheCleaner.xcodeproj \
                -scheme CacheCleaner

# Specific test
xcodebuild test -project CacheCleaner.xcodeproj \
                -scheme CacheCleaner \
                -only-testing:CacheCleanerTests/YourTestClass/testMethod
```

## Documentation

### Code Documentation

Use documentation comments for public APIs:

```swift
/// Calculates the total size of a directory
///
/// - Parameter path: The directory path to scan
/// - Returns: Total size in bytes
/// - Throws: FileSystemError if directory doesn't exist
func getDirectorySize(path: String) throws -> Int64 {
    // Implementation
}
```

### README Updates

Update [README.md](../README.md) if your changes affect:
- Installation instructions
- Usage instructions
- Feature descriptions

### Developer Documentation

Update docs in `docs/` directory if changing:
- Architecture
- Development workflow
- Testing approach

## Issue Reporting

### Before Creating an Issue

1. **Search existing issues** to avoid duplicates
2. **Verify the issue** is reproducible
3. **Collect information** about your environment

### Bug Reports

Include:

```markdown
**Description**
Clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '....'
3. See error

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- macOS version:
- App version:
- Xcode version (if building):

**Screenshots**
If applicable

**Additional Context**
Any other relevant information
```

### Feature Requests

Include:

```markdown
**Description**
Clear description of proposed feature

**Use Case**
Why is this feature needed?

**Proposed Solution**
How should it work?

**Alternatives Considered**
Other approaches you've thought about

**Additional Context**
Mockups, examples, etc.
```

## Development Tips

### Debugging

1. **Enable debug output**:
   ```swift
   print("DEBUG: \(variableName)")
   ```

2. **Use Xcode debugger**: Set breakpoints in key functions

3. **Check logs**: Console.app → Filter for "CacheCleaner"

### Common Tasks

See [DEVELOPMENT.md](DEVELOPMENT.md) for:
- Adding new cache types
- Modifying UI
- Updating icons
- Performance optimization

## Release Process

(For maintainers)

1. Update version number
2. Update CHANGELOG
3. Create and test DMG
4. Create GitHub release
5. Upload DMG to release
6. Update README with release info

## Getting Help

- **Documentation**: Check `docs/` directory
- **Issues**: Search or create GitHub issue
- **Discussions**: Use GitHub Discussions for questions

## Recognition

Contributors are recognized in:
- README.md Contributors section
- Release notes
- GitHub insights

Thank you for contributing to Cache Cleaner!
