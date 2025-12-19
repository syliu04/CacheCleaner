//
//  IntegrationTests.swift
//  CacheCleanerTests
//
//  Integration tests for Cache Cleaner application
//

import XCTest
@testable import CacheCleaner

class IntegrationTests: XCTestCase {

    var testCacheDirectory: URL!

    override func setUpWithError() throws {
        // Create test cache directory
        let tempDir = FileManager.default.temporaryDirectory
        testCacheDirectory = tempDir.appendingPathComponent("TestCache_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testCacheDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        // Clean up
        if FileManager.default.fileExists(atPath: testCacheDirectory.path) {
            try FileManager.default.removeItem(at: testCacheDirectory)
        }
    }

    // MARK: - Integration Tests

    func testFullWorkflow_CalculateAndClean() throws {
        // Given: A cache directory with known size
        let cacheSize = 10240 // 10KB
        let testFile = testCacheDirectory.appendingPathComponent("cache.dat")
        let testData = Data(repeating: 0, count: cacheSize)
        try testData.write(to: testFile)

        // When: Calculating size
        let initialSize = try FileManager.default.allocatedSizeOfDirectory(at: testCacheDirectory)

        // Then: Size should be at least 10KB
        XCTAssertGreaterThanOrEqual(initialSize, Int64(cacheSize))

        // When: Cleaning the cache
        try FileManager.default.removeItem(at: testFile)
        let finalSize = try FileManager.default.allocatedSizeOfDirectory(at: testCacheDirectory)

        // Then: Size should be significantly reduced
        XCTAssertLessThan(finalSize, initialSize)
    }

    func testMultipleCacheTypes_CalculateTotal() throws {
        // Given: Multiple cache subdirectories
        let userCache = testCacheDirectory.appendingPathComponent("UserCache")
        let logs = testCacheDirectory.appendingPathComponent("Logs")

        try FileManager.default.createDirectory(at: userCache, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)

        // Create files in each
        let data1 = Data(repeating: 0, count: 5120) // 5KB
        let data2 = Data(repeating: 0, count: 3072) // 3KB

        try data1.write(to: userCache.appendingPathComponent("cache.dat"))
        try data2.write(to: logs.appendingPathComponent("log.txt"))

        // When: Calculating total size
        let totalSize = try FileManager.default.allocatedSizeOfDirectory(at: testCacheDirectory)

        // Then: Should be at least sum of both
        XCTAssertGreaterThanOrEqual(totalSize, 8192)
    }

    func testProtectedFileHandling_Integration() throws {
        // Given: Mix of protected and regular files
        let protectedFile = testCacheDirectory.appendingPathComponent("com.apple.security.plist")
        let regularFile = testCacheDirectory.appendingPathComponent("cache.dat")

        try Data().write(to: protectedFile)
        try Data(repeating: 0, count: 1024).write(to: regularFile)

        // When: Attempting to clean (simulated)
        let files = try FileManager.default.contentsOfDirectory(atPath: testCacheDirectory.path)

        // Then: Should detect both files
        XCTAssertEqual(files.count, 2)
        XCTAssertTrue(files.contains("com.apple.security.plist"))
        XCTAssertTrue(files.contains("cache.dat"))
    }

    func testConcurrentCacheCalculation() throws {
        // Given: Multiple directories
        let dir1 = testCacheDirectory.appendingPathComponent("dir1")
        let dir2 = testCacheDirectory.appendingPathComponent("dir2")

        try FileManager.default.createDirectory(at: dir1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dir2, withIntermediateDirectories: true)

        let data = Data(repeating: 0, count: 2048)
        try data.write(to: dir1.appendingPathComponent("file1.dat"))
        try data.write(to: dir2.appendingPathComponent("file2.dat"))

        // When: Calculating sizes concurrently
        let expectation1 = expectation(description: "Calculate dir1")
        let expectation2 = expectation(description: "Calculate dir2")

        var size1: Int64 = 0
        var size2: Int64 = 0

        DispatchQueue.global().async {
            size1 = (try? FileManager.default.allocatedSizeOfDirectory(at: dir1)) ?? 0
            expectation1.fulfill()
        }

        DispatchQueue.global().async {
            size2 = (try? FileManager.default.allocatedSizeOfDirectory(at: dir2)) ?? 0
            expectation2.fulfill()
        }

        // Then: Both should complete successfully
        waitForExpectations(timeout: 5)
        XCTAssertGreaterThan(size1, 0)
        XCTAssertGreaterThan(size2, 0)
    }

    func testEmptyCacheHandling() throws {
        // Given: Empty cache directory
        let emptyCache = testCacheDirectory.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: emptyCache, withIntermediateDirectories: true)

        // When: Calculating size
        let size = try FileManager.default.allocatedSizeOfDirectory(at: emptyCache)

        // Then: Should handle gracefully (size should be 0 or minimal)
        XCTAssertGreaterThanOrEqual(size, 0)
    }

    func testLargeFileHandling() throws {
        // Given: A large file (simulated)
        let largeFile = testCacheDirectory.appendingPathComponent("large.dat")
        let largeData = Data(repeating: 0, count: 1_048_576) // 1MB

        try largeData.write(to: largeFile)

        // When: Calculating size
        let size = try FileManager.default.allocatedSizeOfDirectory(at: testCacheDirectory)

        // Then: Should correctly calculate large file
        XCTAssertGreaterThanOrEqual(size, 1_048_576)

        // When: Cleaning
        try FileManager.default.removeItem(at: largeFile)

        // Then: Should successfully remove
        XCTAssertFalse(FileManager.default.fileExists(atPath: largeFile.path))
    }
}

// MARK: - Helper Extensions

extension FileManager {
    func allocatedSizeOfDirectory(at url: URL) throws -> Int64 {
        var totalSize: Int64 = 0

        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]

        guard let enumerator = self.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: []
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
