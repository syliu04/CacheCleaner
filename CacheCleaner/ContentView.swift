//  change
//  ContentView.swift
//  CacheCleaner
//
//  Created by ShengYao Liu on 9/27/25.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State private var statusMessage = "Ready to clean caches"
    @State private var isProcessing = false
    @State private var spaceSaved = "0 MB"
    @State private var totalCacheSize = "0 MB"
    @State private var cacheBreakdown: [CacheType: String] = [:]
    @State private var hasCalculated = false
    @State private var hasCleaned = false
    @State private var selectedCaches = Set<CacheType>()
    
    enum CacheType: String, CaseIterable, Hashable {
        case userCache = "User Cache"
        case systemCache = "System Cache"
        case logs = "Log Files"
        case trash = "Empty Trash"
        
        var path: String {
            switch self {
            case .userCache:
                // Try to get the real user library path
                if let realUserPath = getRealUserPath() {
                    return realUserPath + "/Library/Caches"
                }
                return NSHomeDirectory() + "/Library/Caches"
            case .systemCache:
                return "/Library/Caches"
            case .logs:
                if let realUserPath = getRealUserPath() {
                    return realUserPath + "/Library/Logs"
                }
                return NSHomeDirectory() + "/Library/Logs"
            case .trash:
                if let realUserPath = getRealUserPath() {
                    return realUserPath + "/.Trash"
                }
                // Alternative trash location
                return NSHomeDirectory() + "/.Trash"
            }
        }
        
        // Helper function to get real user path (outside sandbox)
        func getRealUserPath() -> String? {
            // Try to get the actual user's home directory
            let pw = getpwuid(getuid())
            if let pw = pw, let homeDir = pw.pointee.pw_dir {
                return String(cString: homeDir)
            }
            
            // Fallback: try to extract from sandboxed path
            let sandboxPath = NSHomeDirectory()
            if sandboxPath.contains("/Containers/") {
                // Extract username from sandboxed path
                let components = sandboxPath.components(separatedBy: "/")
                if let userIndex = components.firstIndex(of: "Users"),
                   userIndex + 1 < components.count {
                    let username = components[userIndex + 1]
                    return "/Users/\(username)"
                }
            }
            
            return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // App title
            Text("🧹 Cache Cleaner")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Select caches to clean:")
                .font(.headline)
            
            // Cache selection checkboxes
            VStack(alignment: .leading, spacing: 10) {
                ForEach(CacheType.allCases, id: \.self) { cacheType in
                    HStack {
                        Image(systemName: selectedCaches.contains(cacheType) ? "checkmark.square.fill" : "square")
                            .foregroundColor(.blue)
                            .onTapGesture {
                                toggleSelection(for: cacheType)
                            }
                        Text(cacheType.rawValue)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleSelection(for: cacheType)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Status message
            Text(statusMessage)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Cache size breakdown (only show after calculation, before cleaning)
            if hasCalculated && !hasCleaned && !cacheBreakdown.isEmpty {
                VStack(spacing: 8) {
                    Text("Total cache size: \(totalCacheSize)")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    // Individual cache sizes breakdown
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(cacheBreakdown.keys).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { cacheType in
                            if selectedCaches.contains(cacheType) {
                                HStack {
                                    Text("• \(cacheType.rawValue):")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(cacheBreakdown[cacheType] ?? "0 MB")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
            
            // Space saved (ONLY show after cleaning is complete)
            if hasCleaned {
                Text("Space saved: \(spaceSaved)")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                Button("Calculate Size") {
                    calculateCacheSize()
                }
                .buttonStyle(.bordered)
                .disabled(selectedCaches.isEmpty || isProcessing)
                
                Button("Clean Selected") {
                    cleanCaches()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCaches.isEmpty || isProcessing)
            }
            
            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
            }
            
            // Warning
            Text("⚠️ Close all applications before cleaning")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.top)
        }
        .padding(30)
        .frame(width: 500, height: 500)
    }
    
    // Helper to toggle checkboxes
    private func toggleSelection(for cacheType: CacheType) {
        if selectedCaches.contains(cacheType) {
            selectedCaches.remove(cacheType)
        } else {
            selectedCaches.insert(cacheType)
        }
        
        // Reset states when selection changes
        hasCalculated = false
        hasCleaned = false
        cacheBreakdown.removeAll()
        statusMessage = "Ready to clean caches"
    }
    
    // Helper to calculate total size of selected caches
    private func calculateCacheSize() {
        isProcessing = true
        hasCalculated = false
        hasCleaned = false
        statusMessage = "Calculating cache sizes..."
        cacheBreakdown.removeAll()
        
        DispatchQueue.global(qos: .background).async {
            var totalSize: Int64 = 0
            var breakdown: [CacheType: String] = [:]
            
            for cacheType in selectedCaches {
                let size = getDirectorySize(path: cacheType.path)
                totalSize += size
                breakdown[cacheType] = formatBytes(size)
                print("DEBUG: \(cacheType.rawValue) size: \(formatBytes(size)) at path: \(cacheType.path)")
            }
            
            DispatchQueue.main.async {
                totalCacheSize = formatBytes(totalSize)
                cacheBreakdown = breakdown
                hasCalculated = true
                statusMessage = "Cache sizes calculated. Ready to clean."
                isProcessing = false
            }
        }
    }
    
    // Helper to clean selected caches
    private func cleanCaches() {
        isProcessing = true
        statusMessage = "Cleaning caches..."
        var totalCleaned: Int64 = 0
        
        DispatchQueue.global(qos: .background).async {
            for cacheType in selectedCaches {
                if cacheType == .systemCache {
                    // ⚠️ Requires sudo privileges – skip in this demo
                    DispatchQueue.main.async {
                        statusMessage = "System cache requires admin privileges - skipping"
                    }
                    continue
                }
                
                let sizeBeforeCleaning = getDirectorySize(path: cacheType.path)
                clearDirectory(at: cacheType.path)
                let sizeAfterCleaning = getDirectorySize(path: cacheType.path)
                let cleaned = sizeBeforeCleaning - sizeAfterCleaning
                totalCleaned += cleaned
                
                print("DEBUG: Cleaned \(formatBytes(cleaned)) from \(cacheType.rawValue)")
            }
            
            DispatchQueue.main.async {
                spaceSaved = formatBytes(totalCleaned)
                statusMessage = "Successfully cleaned! Freed up \(formatBytes(totalCleaned))"
                isProcessing = false
            }
        }
    }
    
    // Helper to get size of a directory
    private func getDirectorySize(path: String) -> Int64 {
        let fileManager = FileManager.default
        var size: Int64 = 0
        var accessibleFileCount = 0
        var deniedFileCount = 0
        
        // Check if directory exists and is readable
        guard fileManager.fileExists(atPath: path) else {
            print("DEBUG: Directory does not exist: \(path)")
            return 0
        }
        
        // First try to read directory contents directly
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            for item in contents {
                let fullPath = "\(path)/\(item)"
                
                // Skip system-protected directories that we know we can't access
                if isProtectedSystemFile(item) {
                    continue
                }
                
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: fullPath)
                    
                    if let fileType = attributes[.type] as? FileAttributeType {
                        if fileType == .typeRegular {
                            // Regular file
                            if let fileSize = attributes[.size] as? Int64 {
                                size += fileSize
                                accessibleFileCount += 1
                            }
                        } else if fileType == .typeDirectory {
                            // Recursively get directory size
                            let subSize = getDirectorySize(path: fullPath)
                            size += subSize
                            if subSize > 0 {
                                accessibleFileCount += 1
                            }
                        }
                    }
                } catch {
                    deniedFileCount += 1
                    // Skip files we can't access
                }
            }
            
            if accessibleFileCount > 0 {
                print("DEBUG: \(path) - Accessible files: \(accessibleFileCount), Denied: \(deniedFileCount), Total size: \(formatBytes(size))")
            }
            
        } catch {
            print("DEBUG: Cannot read directory: \(path) - \(error)")
            return 0
        }
        
        return size
    }
    
    // Helper to identify protected system files we should skip
    private func isProtectedSystemFile(_ filename: String) -> Bool {
        let protectedPrefixes = [
            "com.apple.",
            "CloudKit",
            "FamilyCircle",
            ".DS_Store"
        ]
        
        return protectedPrefixes.contains { filename.hasPrefix($0) } || filename.starts(with: ".")
    }
    
    // Helper to delete contents of a directory
    private func clearDirectory(at path: String) {
        let fileManager = FileManager.default
        var deletedCount = 0
        var skippedCount = 0
        
        guard fileManager.fileExists(atPath: path) else {
            print("DEBUG: Directory does not exist: \(path)")
            return
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            for item in contents {
                let fullPath = "\(path)/\(item)"
                
                // Skip protected files and system files
                if isProtectedSystemFile(item) {
                    print("DEBUG: Skipping protected file: \(item)")
                    skippedCount += 1
                    continue
                }
                
                do {
                    try fileManager.removeItem(atPath: fullPath)
                    print("DEBUG: Successfully deleted: \(item)")
                    deletedCount += 1
                } catch {
                    print("DEBUG: Failed to delete \(item): \(error)")
                    skippedCount += 1
                }
            }
            
            print("DEBUG: \(path) - Deleted: \(deletedCount), Skipped: \(skippedCount)")
            
        } catch {
            print("DEBUG: Error reading directory contents: \(error)")
        }
    }
    
    // Helper to format bytes into readable string
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .decimal
        return formatter.string(fromByteCount: bytes)
    }
}
