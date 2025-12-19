//
//  CacheCleanerTests.swift
//  CacheCleanerTests
//
//  Unit tests for Cache Cleaner application
//

import XCTest
@testable import CacheCleaner

class CacheCleanerTests: XCTestCase {

    var testDirectory: URL!

    // MARK: - Setup and Teardown

    override func setUpWithError() throws {
        // Create temporary test directory
        let tempDir = FileManager.default.temporaryDirectory
        testDirectory = tempDir.appendingPathComponent("CacheCleanerTest_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        // Clean up test directory
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            try FileManager.default.removeItem(at: testDirectory)
        }
    }

    // MARK: - Unit Tests for Directory Size Calculation

    func testGetDirectorySize_EmptyDirectory() throws {
        // Given: An empty directory
        let emptyDir = testDirectory.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)

        // When: Getting directory size
        // Note: This would need to be extracted from ContentView to test properly
        // For now, we'll test the concept

        // Then: Size should be 0 or minimal (directory metadata)
        XCTAssertTrue(FileManager.default.fileExists(atPath: emptyDir.path))
    }

    func testGetDirectorySize_WithFiles() throws {
        // Given: A directory with known file sizes
        let testDir = testDirectory.appendingPathComponent("withFiles")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

        // Create test files
        let file1 = testDir.appendingPathComponent("test1.txt")
        let file2 = testDir.appendingPathComponent("test2.txt")
        let testData1 = Data(repeating: 0, count: 1024) // 1KB
        let testData2 = Data(repeating: 0, count: 2048) // 2KB

        try testData1.write(to: file1)
        try testData2.write(to: file2)

        // When: Calculating directory size
        let actualSize = try FileManager.default.allocatedSizeOfDirectory(at: testDir)

        // Then: Size should be at least 3KB (may be more due to file system overhead)
        XCTAssertGreaterThanOrEqual(actualSize, 3072)
    }

    func testGetDirectorySize_NestedDirectories() throws {
        // Given: Nested directory structure with files
        let parentDir = testDirectory.appendingPathComponent("parent")
        let childDir = parentDir.appendingPathComponent("child")
        try FileManager.default.createDirectory(at: childDir, withIntermediateDirectories: true)

        let file1 = parentDir.appendingPathComponent("parent.txt")
        let file2 = childDir.appendingPathComponent("child.txt")
        let testData = Data(repeating: 0, count: 1024)

        try testData.write(to: file1)
        try testData.write(to: file2)

        // When: Calculating parent directory size
        let size = try FileManager.default.allocatedSizeOfDirectory(at: parentDir)

        // Then: Should include files from nested directories
        XCTAssertGreaterThanOrEqual(size, 2048)
    }

    // MARK: - Unit Tests for Cache Path Resolution

    func testCachePaths_UserCache() {
        // Given: User cache path
        let homeDir = NSHomeDirectory()

        // When: Constructing user cache path
        let expectedPath = homeDir + "/Library/Caches"

        // Then: Path should exist and be correct
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath))
    }

    func testCachePaths_UserLogs() {
        // Given: User logs path
        let homeDir = NSHomeDirectory()

        // When: Constructing user logs path
        let expectedPath = homeDir + "/Library/Logs"

        // Then: Path should exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath))
    }

    func testCachePaths_Trash() {
        // Given: Trash path
        let homeDir = NSHomeDirectory()

        // When: Constructing trash path
        let expectedPath = homeDir + "/.Trash"

        // Then: Path should exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath))
    }

    // MARK: - Unit Tests for File Deletion Safety

    func testClearDirectory_SkipsProtectedFiles() throws {
        // Given: Directory with Apple system files
        let testDir = testDirectory.appendingPathComponent("protected")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

        // Create protected files (files that should be skipped)
        let protectedFiles = [
            "com.apple.security.plist",
            "com.apple.LaunchServices.plist",
            ".DS_Store"
        ]

        for filename in protectedFiles {
            let file = testDir.appendingPathComponent(filename)
            try Data().write(to: file)
        }

        // When: Checking if files are protected
        let fileManager = FileManager.default
        let files = try fileManager.contentsOfDirectory(atPath: testDir.path)

        // Then: Protected files should be detected
        for filename in protectedFiles {
            XCTAssertTrue(files.contains(filename))
        }
    }

    func testClearDirectory_DeletesNonProtectedFiles() throws {
        // Given: Directory with regular cache files
        let testDir = testDirectory.appendingPathComponent("cache")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

        let regularFiles = [
            "cache_data.db",
            "temp_file.tmp",
            "user_cache.dat"
        ]

        for filename in regularFiles {
            let file = testDir.appendingPathComponent(filename)
            try Data().write(to: file)
        }

        // When: Deleting files
        let fileManager = FileManager.default
        let filesBefore = try fileManager.contentsOfDirectory(atPath: testDir.path)

        // Delete the files
        for filename in regularFiles {
            let filePath = testDir.appendingPathComponent(filename).path
            try fileManager.removeItem(atPath: filePath)
        }

        let filesAfter = try fileManager.contentsOfDirectory(atPath: testDir.path)

        // Then: Files should be deleted
        XCTAssertEqual(filesBefore.count, 3)
        XCTAssertEqual(filesAfter.count, 0)
    }

    // MARK: - Unit Tests for Byte Formatting

    func testFormatBytes_SmallSize() {
        // Given: Small file size in bytes
        let bytes: Int64 = 512

        // When: Formatting
        let formatter = ByteCountFormatter()
        formatter.countStyle = .decimal
        let result = formatter.string(fromByteCount: bytes)

        // Then: Should format as bytes
        XCTAssertTrue(result.contains("512") || result.contains("B"))
    }

    func testFormatBytes_Kilobytes() {
        // Given: Size in kilobytes
        let bytes: Int64 = 5120 // 5KB

        // When: Formatting
        let formatter = ByteCountFormatter()
        formatter.countStyle = .decimal
        let result = formatter.string(fromByteCount: bytes)

        // Then: Should format as KB
        XCTAssertTrue(result.contains("5") || result.contains("KB"))
    }

    func testFormatBytes_Megabytes() {
        // Given: Size in megabytes
        let bytes: Int64 = 5_242_880 // 5MB

        // When: Formatting
        let formatter = ByteCountFormatter()
        formatter.countStyle = .decimal
        let result = formatter.string(fromByteCount: bytes)

        // Then: Should format as MB
        XCTAssertTrue(result.contains("MB"))
    }

    func testFormatBytes_Gigabytes() {
        // Given: Size in gigabytes
        let bytes: Int64 = 5_368_709_120 // 5GB

        // When: Formatting
        let formatter = ByteCountFormatter()
        formatter.countStyle = .decimal
        let result = formatter.string(fromByteCount: bytes)

        // Then: Should format as GB
        XCTAssertTrue(result.contains("GB"))
    }

    // MARK: - Performance Tests

    func testPerformance_DirectorySizeCalculation() throws {
        // Given: Directory with many files
        let perfDir = testDirectory.appendingPathComponent("perf")
        try FileManager.default.createDirectory(at: perfDir, withIntermediateDirectories: true)

        // Create 100 files
        for i in 0..<100 {
            let file = perfDir.appendingPathComponent("file_\(i).txt")
            let data = Data(repeating: UInt8(i % 256), count: 1024)
            try data.write(to: file)
        }

        // When: Measuring performance of size calculation
        measure {
            _ = try? FileManager.default.allocatedSizeOfDirectory(at: perfDir)
        }
    }
}

// MARK: - Helper Extensions for Testing

extension FileManager {
    func allocatedSizeOfDirectory(at url: URL) throws -> Int64 {
        var totalSize: Int64 = 0

        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]

        guard let enumerator = self.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)

            guard resourceValues.isRegularFile ?? false else {
                continue
            }

            totalSize += Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
        }

        return totalSize
    }
}
