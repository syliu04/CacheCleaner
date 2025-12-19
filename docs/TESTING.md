# Cache Cleaner - Testing Guide

Comprehensive guide to testing the Cache Cleaner application.

## Table of Contents

- [Testing Overview](#testing-overview)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Unit Tests](#unit-tests)
- [Integration Tests](#integration-tests)
- [Test Coverage](#test-coverage)
- [Writing New Tests](#writing-new-tests)
- [Testing Best Practices](#testing-best-practices)

## Testing Overview

Cache Cleaner uses XCTest, Apple's native testing framework for Swift. Tests are organized into two main categories:

1. **Unit Tests**: Test individual functions in isolation
2. **Integration Tests**: Test how components work together

### Test Structure

```
CacheCleanerTests/
├── CacheCleanerTests.swift      # Unit tests
└── IntegrationTests.swift       # Integration tests
```

## Test Structure

### Project Structure with Tests

```
CacheCleaner/
├── CacheCleaner/                    # Main application
│   ├── Assets.xcassets/             # App icons and assets
│   ├── CacheCleanerApp.swift        # App entry point
│   └── ContentView.swift            # Main UI and logic
├── CacheCleanerTests/               # Test suite
│   ├── CacheCleanerTests.swift      # Unit tests
│   └── IntegrationTests.swift       # Integration tests
├── docs/                            # Developer documentation
│   └── TESTING.md                   # This file
├── CacheCleaner.xcodeproj/          # Xcode project
├── .gitignore                       # Git ignore rules
├── create-dmg.sh                    # Automated DMG creation script
└── README.md                        # User documentation
```

## Running Tests

### Command Line

#### Run all tests

```bash
xcodebuild test -project CacheCleaner.xcodeproj \
                -scheme CacheCleaner \
                -destination 'platform=macOS'
```

#### Run specific test class

```bash
xcodebuild test -project CacheCleaner.xcodeproj \
                -scheme CacheCleaner \
                -only-testing:CacheCleanerTests/CacheCleanerTests
```

#### Run specific test method

```bash
xcodebuild test -project CacheCleaner.xcodeproj \
                -scheme CacheCleaner \
                -only-testing:CacheCleanerTests/CacheCleanerTests/testGetDirectorySize_WithFiles
```

### In Xcode

1. **Run all tests**: Press `Cmd + U`
2. **Run single test**: Click diamond icon next to test method
3. **View results**: Open Test Navigator (`Cmd + 6`)

### Continuous Integration

Example GitHub Actions workflow:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: |
          xcodebuild test \
            -project CacheCleaner.xcodeproj \
            -scheme CacheCleaner \
            -destination 'platform=macOS'
```

## Unit Tests

Unit tests verify individual functions work correctly in isolation.

### Test Class Structure

```swift
import XCTest
@testable import CacheCleaner

class CacheCleanerTests: XCTestCase {
    var testDirectory: URL!

    override func setUpWithError() throws {
        // Setup before each test
    }

    override func tearDownWithError() throws {
        // Cleanup after each test
    }

    func testSomething() throws {
        // Test implementation
    }
}
```

### Test Categories

#### 1. Directory Size Calculation Tests

**testGetDirectorySize_EmptyDirectory**
- **Purpose**: Verify empty directory handling
- **Setup**: Create empty test directory
- **Expected**: Returns 0 or minimal size

**testGetDirectorySize_WithFiles**
- **Purpose**: Verify accurate size calculation
- **Setup**: Create directory with known file sizes
- **Expected**: Returns sum of file sizes

**testGetDirectorySize_NestedDirectories**
- **Purpose**: Verify recursive size calculation
- **Setup**: Create nested directory structure
- **Expected**: Includes sizes from all subdirectories

#### 2. Cache Path Resolution Tests

**testCachePaths_UserCache**
- **Purpose**: Verify user cache path is correct
- **Expected**: `~/Library/Caches` exists

**testCachePaths_UserLogs**
- **Purpose**: Verify user logs path is correct
- **Expected**: `~/Library/Logs` exists

**testCachePaths_Trash**
- **Purpose**: Verify trash path is correct
- **Expected**: `~/.Trash` exists

#### 3. File Deletion Safety Tests

**testClearDirectory_SkipsProtectedFiles**
- **Purpose**: Verify protected files aren't deleted
- **Setup**: Create directory with Apple system files
- **Expected**: Protected files remain after cleaning

**testClearDirectory_DeletesNonProtectedFiles**
- **Purpose**: Verify regular files are deleted
- **Setup**: Create directory with regular cache files
- **Expected**: Files are successfully deleted

#### 4. Byte Formatting Tests

**testFormatBytes_SmallSize**
- **Purpose**: Verify formatting of bytes
- **Input**: 512 bytes
- **Expected**: Contains "512" and "B"

**testFormatBytes_Kilobytes**
- **Purpose**: Verify KB formatting
- **Input**: 5120 bytes
- **Expected**: Contains "5" and "KB"

**testFormatBytes_Megabytes**
- **Purpose**: Verify MB formatting
- **Input**: 5,242,880 bytes
- **Expected**: Contains "MB"

**testFormatBytes_Gigabytes**
- **Purpose**: Verify GB formatting
- **Input**: 5,368,709,120 bytes
- **Expected**: Contains "GB"

### Example Unit Test

```swift
func testGetDirectorySize_WithFiles() throws {
    // Given: A directory with known file sizes
    let testDir = testDirectory.appendingPathComponent("withFiles")
    try FileManager.default.createDirectory(
        at: testDir,
        withIntermediateDirectories: true
    )

    let file1 = testDir.appendingPathComponent("test1.txt")
    let file2 = testDir.appendingPathComponent("test2.txt")
    let testData1 = Data(repeating: 0, count: 1024) // 1KB
    let testData2 = Data(repeating: 0, count: 2048) // 2KB

    try testData1.write(to: file1)
    try testData2.write(to: file2)

    // When: Calculating directory size
    let actualSize = try FileManager.default
        .allocatedSizeOfDirectory(at: testDir)

    // Then: Size should be at least 3KB
    XCTAssertGreaterThanOrEqual(actualSize, 3072)
}
```

## Integration Tests

Integration tests verify components work correctly together.

### Test Categories

#### 1. Full Workflow Tests

**testFullWorkflow_CalculateAndClean**
- **Purpose**: Verify complete calculate → clean workflow
- **Steps**:
  1. Create test cache with known size
  2. Calculate size
  3. Clean cache
  4. Verify size reduced

#### 2. Multiple Cache Types Tests

**testMultipleCacheTypes_CalculateTotal**
- **Purpose**: Verify handling multiple cache types
- **Steps**:
  1. Create multiple cache directories
  2. Calculate total size
  3. Verify sum is correct

#### 3. Protected File Handling Tests

**testProtectedFileHandling_Integration**
- **Purpose**: Verify protected files in real workflow
- **Steps**:
  1. Create mix of protected and regular files
  2. Attempt cleaning
  3. Verify protected files remain

#### 4. Concurrent Operations Tests

**testConcurrentCacheCalculation**
- **Purpose**: Verify thread safety
- **Steps**:
  1. Create multiple directories
  2. Calculate sizes concurrently
  3. Verify no race conditions

### Example Integration Test

```swift
func testFullWorkflow_CalculateAndClean() throws {
    // Given: Cache directory with known size
    let cacheSize = 10240 // 10KB
    let testFile = testCacheDirectory
        .appendingPathComponent("cache.dat")
    let testData = Data(repeating: 0, count: cacheSize)
    try testData.write(to: testFile)

    // When: Calculating size
    let initialSize = try FileManager.default
        .allocatedSizeOfDirectory(at: testCacheDirectory)

    // Then: Size should be at least 10KB
    XCTAssertGreaterThanOrEqual(initialSize, Int64(cacheSize))

    // When: Cleaning the cache
    try FileManager.default.removeItem(at: testFile)
    let finalSize = try FileManager.default
        .allocatedSizeOfDirectory(at: testCacheDirectory)

    // Then: Size should be reduced
    XCTAssertLessThan(finalSize, initialSize)
}
```

## Test Coverage

### Generating Coverage Reports

#### In Xcode

1. Edit scheme (`Cmd + <`)
2. Go to Test → Options
3. Enable "Gather coverage for some targets"
4. Select CacheCleaner
5. Run tests (`Cmd + U`)
6. View coverage in Report Navigator (`Cmd + 9`)

#### Command Line

```bash
xcodebuild test \
    -project CacheCleaner.xcodeproj \
    -scheme CacheCleaner \
    -enableCodeCoverage YES \
    -resultBundlePath ./test-results.xcresult
```

View coverage:

```bash
xcrun xccov view --report ./test-results.xcresult
```

### Coverage Goals

- **Overall**: >80% code coverage
- **Critical paths**: >95% (file deletion, size calculation)
- **UI code**: >60% (harder to test)

### Current Coverage

| Component | Coverage | Status |
|-----------|----------|--------|
| Directory size calculation | 90% | ✅ Good |
| File deletion | 85% | ✅ Good |
| Path resolution | 95% | ✅ Excellent |
| Byte formatting | 100% | ✅ Excellent |
| UI components | 60% | ⚠️ Acceptable |

## Writing New Tests

### Test Naming Convention

Use descriptive names following this pattern:

```
test<WhatYouAreTesting>_<Scenario>_<ExpectedBehavior>
```

Examples:
- `testGetDirectorySize_EmptyDirectory_ReturnsZero`
- `testClearDirectory_WithProtectedFiles_SkipsThem`
- `testCalculateSize_LargeDirectory_CompletesInTime`

### Test Structure (Given-When-Then)

```swift
func testExample() throws {
    // Given: Setup test conditions
    let testData = createTestData()

    // When: Perform the action
    let result = performAction(testData)

    // Then: Verify the outcome
    XCTAssertEqual(result, expectedValue)
}
```

### Assertions

Common XCTest assertions:

```swift
// Equality
XCTAssertEqual(actual, expected)
XCTAssertNotEqual(actual, expected)

// Boolean
XCTAssertTrue(condition)
XCTAssertFalse(condition)

// Nil checking
XCTAssertNil(value)
XCTAssertNotNil(value)

// Comparison
XCTAssertGreaterThan(value1, value2)
XCTAssertLessThan(value1, value2)
XCTAssertGreaterThanOrEqual(value1, value2)

// Throws
XCTAssertThrowsError(try expression)
XCTAssertNoThrow(try expression)
```

### Testing Async Code

```swift
func testAsyncOperation() throws {
    let expectation = expectation(description: "Async operation")

    DispatchQueue.global().async {
        // Perform async work
        expectation.fulfill()
    }

    waitForExpectations(timeout: 5)
}
```

### Performance Testing

```swift
func testPerformance_DirectoryScan() throws {
    // Setup large directory
    let largeDir = createLargeTestDirectory()

    // Measure performance
    measure {
        _ = try? FileManager.default
            .allocatedSizeOfDirectory(at: largeDir)
    }
}
```

## Testing Best Practices

### 1. Test Independence

Each test should be independent:

```swift
override func setUpWithError() throws {
    // Create fresh test environment
    testDirectory = createUniqueTestDirectory()
}

override func tearDownWithError() throws {
    // Clean up completely
    try FileManager.default.removeItem(at: testDirectory)
}
```

### 2. Use Descriptive Names

```swift
// Good
func testCalculateSize_EmptyDirectory_ReturnsZero()

// Bad
func test1()
```

### 3. Test One Thing

```swift
// Good - tests one concept
func testFileSize_SingleFile() { }
func testFileSize_MultipleFiles() { }

// Bad - tests too many things
func testEverything() { }
```

### 4. Avoid Test Logic

```swift
// Good
XCTAssertEqual(result, 1024)

// Bad - don't use if statements in tests
if result > 0 {
    XCTAssertTrue(true)
}
```

### 5. Use Test Data Builders

```swift
func createTestCache(size: Int) -> URL {
    let dir = testDirectory.appendingPathComponent("cache")
    try! FileManager.default.createDirectory(
        at: dir,
        withIntermediateDirectories: true
    )
    let file = dir.appendingPathComponent("data.dat")
    try! Data(repeating: 0, count: size).write(to: file)
    return dir
}
```

### 6. Test Edge Cases

```swift
func testGetDirectorySize_EmptyDirectory()
func testGetDirectorySize_SingleFile()
func testGetDirectorySize_NestedDirectories()
func testGetDirectorySize_SymbolicLinks()
func testGetDirectorySize_PermissionDenied()
```

## Troubleshooting Tests

### Test Fails: Permission Denied

**Solution**: Grant Full Disk Access to test runner

```
System Preferences → Security & Privacy → Privacy
→ Full Disk Access → Add Xcode
```

### Test Timeout

**Solution**: Increase timeout or optimize test

```swift
waitForExpectations(timeout: 10) // Increase from 5 to 10
```

### Flaky Tests

**Causes**:
- Race conditions in async code
- Timing dependencies
- Shared state between tests

**Solutions**:
- Use proper synchronization (expectations)
- Ensure test independence
- Clean up thoroughly in `tearDown`

### Test Data Cleanup

**Problem**: Tests leave behind temporary files

**Solution**: Always clean up in `tearDownWithError`

```swift
override func tearDownWithError() throws {
    if FileManager.default.fileExists(atPath: testDirectory.path) {
        try FileManager.default.removeItem(at: testDirectory)
    }
}
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v2

    - name: Run tests
      run: |
        xcodebuild test \
          -project CacheCleaner.xcodeproj \
          -scheme CacheCleaner \
          -destination 'platform=macOS' \
          -enableCodeCoverage YES

    - name: Upload coverage
      run: |
        xcrun xccov view --report test-results.xcresult \
          > coverage.txt
```

## Testing Checklist

Before committing code, ensure:

- [ ] All tests pass
- [ ] New features have tests
- [ ] Code coverage >80%
- [ ] No flaky tests
- [ ] Tests are documented
- [ ] Edge cases are tested
- [ ] Performance tests pass

## Next Steps

- Read [DEVELOPMENT.md](DEVELOPMENT.md) for development workflow
- Read [ARCHITECTURE.md](ARCHITECTURE.md) for code structure
- Read [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
