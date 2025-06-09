//
//  OSDUIManager.swift
//  TheBoringWorker
//
//  Enhanced version with improved OSDUIHelper management
//

import Foundation
import Cocoa

class OSDUIManager {
    private init() {}
    
    private static var monitoringTimer: Timer?
    private static var isOSDDisabled = false
    private static let MONITORING_INTERVAL: TimeInterval = 2.0
    private static let PROCESS_WAIT_TIME: UInt32 = 750000 // 750ms in microseconds
    
    // MARK: - Public Interface
    
    public static func start() {
        stopMonitoring()
        enableOSDUIHelper()
        isOSDDisabled = false
        NSLog("OSDUIManager: OSD system re-enabled")
    }
    
    public static func stop() {
        disableOSDUIHelper()
        startContinuousMonitoring()
        isOSDDisabled = true
        NSLog("OSDUIManager: OSD system disabled with continuous monitoring")
    }
    
    // MARK: - Private Implementation
    
    private static func disableOSDUIHelper() {
        let dispatchGroup = DispatchGroup()
        
        // Step 1: Ensure OSDUIHelper is running first
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            kickstartOSDUIHelper()
            usleep(PROCESS_WAIT_TIME)
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        
        // Step 2: Terminate the process completely
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            terminateOSDUIHelper()
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        
        // Step 3: Verify termination
        if !isOSDUIHelperRunning() {
            NSLog("OSDUIManager: Successfully disabled OSDUIHelper")
        } else {
            NSLog("OSDUIManager: Warning - OSDUIHelper may still be running")
            // Try alternative termination method
            forceTerminateOSDUIHelper()
        }
    }
    
    private static func enableOSDUIHelper() {
        do {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            task.arguments = ["kickstart", "gui/\(getuid())/com.apple.OSDUIHelper"]
            try task.run()
            task.waitUntilExit()
            usleep(PROCESS_WAIT_TIME)
            NSLog("OSDUIManager: OSDUIHelper re-enabled")
        } catch {
            NSLog("OSDUIManager: Error re-enabling OSDUIHelper: \(error)")
        }
    }
    
    private static func kickstartOSDUIHelper() {
        do {
            let kickstart = Process()
            kickstart.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            kickstart.arguments = ["kickstart", "gui/\(getuid())/com.apple.OSDUIHelper"]
            try kickstart.run()
            kickstart.waitUntilExit()
        } catch {
            NSLog("OSDUIManager: Error kickstarting OSDUIHelper: \(error)")
        }
    }
    
    private static func terminateOSDUIHelper() {
        do {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            task.arguments = ["-9", "OSDUIHelper"]
            try task.run()
            task.waitUntilExit()
        } catch {
            NSLog("OSDUIManager: Error terminating OSDUIHelper: \(error)")
        }
    }
    
    private static func forceTerminateOSDUIHelper() {
        do {
            // Alternative method: Use pkill with more specific targeting
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            task.arguments = ["-f", "OSDUIHelper"]
            try task.run()
            task.waitUntilExit()
            
            // Also try to unload the service
            let unloadTask = Process()
            unloadTask.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            unloadTask.arguments = ["remove", "com.apple.OSDUIHelper"]
            try unloadTask.run()
            unloadTask.waitUntilExit()
            
        } catch {
            NSLog("OSDUIManager: Error in force termination: \(error)")
        }
    }
    
    private static func isOSDUIHelperRunning() -> Bool {
        do {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
            task.arguments = ["OSDUIHelper"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            NSLog("OSDUIManager: Error checking OSDUIHelper status: \(error)")
            return false
        }
    }
    
    // MARK: - Continuous Monitoring
    
    private static func startContinuousMonitoring() {
        stopMonitoring() // Ensure no duplicate timers
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: MONITORING_INTERVAL, repeats: true) { _ in
            guard isOSDDisabled else { return }
            
            if isOSDUIHelperRunning() {
                NSLog("OSDUIManager: Detected OSDUIHelper restart, re-disabling...")
                terminateOSDUIHelper()
                
                // If it keeps restarting, try the force method
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) {
                    if isOSDUIHelperRunning() {
                        forceTerminateOSDUIHelper()
                    }
                }
            }
        }
        
        // Ensure timer runs in all run loop modes
        if let timer = monitoringTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private static func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - System Event Handling
    
    public static func handleSystemWake() {
        guard isOSDDisabled else { return }
        
        // Re-disable OSD after system wake as macOS often restarts services
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2.0) {
            disableOSDUIHelper()
        }
    }
    
    public static func handleDisplayConfigurationChange() {
        guard isOSDDisabled else { return }
        
        // Re-disable OSD after display changes
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
            disableOSDUIHelper()
        }
    }
}

// MARK: - System Event Notifications Extension

extension OSDUIManager {
    static func setupSystemEventMonitoring() {
        // Monitor for system wake events
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            handleSystemWake()
        }
        
        // Monitor for display configuration changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            handleDisplayConfigurationChange()
        }
    }
    
    static func removeSystemEventMonitoring() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
}
