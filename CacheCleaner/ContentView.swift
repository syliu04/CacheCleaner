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
    @State private var showSuccess = false
    @State private var pulseAnimation = false
    
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
        ZStack {
            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    hasCleaned ? Color.green.opacity(0.1) : Color.blue.opacity(0.1),
                    hasCleaned ? Color.green.opacity(0.05) : Color.cyan.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.0), value: hasCleaned)

            ScrollView {
                VStack(spacing: 25) {
                // App title with icon
                HStack(spacing: 15) {
                    Image(systemName: hasCleaned ? "checkmark.circle.fill" : "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: hasCleaned ? [.green, .mint] : [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(pulseAnimation ? 360 : 0))
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: pulseAnimation)

                    Text("Cache Cleaner")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.top, 10)

                // Cache selection card
                VStack(alignment: .leading, spacing: 15) {
                    Text("Select Caches to Clean")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(spacing: 12) {
                        ForEach(CacheType.allCases, id: \.self) { cacheType in
                            CacheSelectionRow(
                                cacheType: cacheType,
                                isSelected: selectedCaches.contains(cacheType),
                                onToggle: { toggleSelection(for: cacheType) }
                            )
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.8))
                        .shadow(color: .blue.opacity(0.1), radius: 10, x: 0, y: 5)
                )

                // Simple progress indicator
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .tint(hasCleaned ? .green : .blue)
                }

                // Status message with animation
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .transition(.opacity)
                    .id(statusMessage)

                // Cache size breakdown with animation
                if hasCalculated && !hasCleaned && !cacheBreakdown.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "chart.pie.fill")
                                .foregroundColor(.blue)
                            Text("Total: \(totalCacheSize)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(cacheBreakdown.keys).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { cacheType in
                                if selectedCaches.contains(cacheType) {
                                    HStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.6))
                                            .frame(width: 8, height: 8)
                                        Text(cacheType.rawValue)
                                            .font(.callout)
                                        Spacer()
                                        Text(cacheBreakdown[cacheType] ?? "0 MB")
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(10)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.8))
                            .shadow(color: .blue.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Success card with animation
                if hasCleaned {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                            .scaleEffect(showSuccess ? 1.0 : 0.5)
                            .opacity(showSuccess ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showSuccess)

                        Text("Space Freed!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        Text(spaceSaved)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .green.opacity(0.2), radius: 15, x: 0, y: 5)
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                // Action Buttons with gradient
                HStack(spacing: 15) {
                    Button(action: { calculateCacheSize() }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("Calculate Size")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .disabled(selectedCaches.isEmpty || isProcessing)
                    .opacity(selectedCaches.isEmpty || isProcessing ? 0.5 : 1.0)
                    .buttonStyle(.plain)

                    Button(action: { cleanCaches() }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clean Now")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .disabled(selectedCaches.isEmpty || isProcessing)
                    .opacity(selectedCaches.isEmpty || isProcessing ? 0.5 : 1.0)
                    .buttonStyle(.plain)
                }

                // Warning
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Close all applications before cleaning")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.bottom, 10)
                }
                .padding(30)
            }
        }
        .frame(minWidth: 600, idealWidth: 600, maxWidth: 800, minHeight: 600, idealHeight: 700, maxHeight: .infinity)
        .onAppear {
            pulseAnimation = true
        }
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
        showSuccess = false
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
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    totalCacheSize = formatBytes(totalSize)
                    cacheBreakdown = breakdown
                    hasCalculated = true
                    statusMessage = "Cache sizes calculated. Ready to clean."
                    isProcessing = false
                }
            }
        }
    }
    
    // Helper to clean selected caches
    private func cleanCaches() {
        isProcessing = true
        hasCleaned = false
        showSuccess = false
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
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    spaceSaved = formatBytes(totalCleaned)
                    statusMessage = "Successfully cleaned! Freed up \(formatBytes(totalCleaned))"
                    hasCleaned = true
                    isProcessing = false
                }

                // Trigger success animation after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        showSuccess = true
                    }
                }
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

// MARK: - Custom Views

struct CacheSelectionRow: View {
    let cacheType: ContentView.CacheType
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    )

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

            Text(cacheType.rawValue)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: icon(for: cacheType))
                .foregroundColor(isSelected ? .blue : .gray.opacity(0.6))
                .font(.system(size: 18))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue.opacity(0.05) : Color.gray.opacity(0.05))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private func icon(for cacheType: ContentView.CacheType) -> String {
        switch cacheType {
        case .userCache: return "person.circle.fill"
        case .systemCache: return "externaldrive.fill"
        case .logs: return "doc.text.fill"
        case .trash: return "trash.fill"
        }
    }
}
