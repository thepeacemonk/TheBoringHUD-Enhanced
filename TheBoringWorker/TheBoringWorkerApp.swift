//
//  TheBoringWorkerApp.swift
//  TheBoringWorker
//

import SwiftData
import SwiftUI

@main
struct TheBoringWorkerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("showMenuBarIcon") var showMenuBarIcon: Bool = true
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(self.appDelegate.vm)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 600)
        
        MenuBarExtra("boring.worker", systemImage: "dial.medium.fill", isInserted: $showMenuBarIcon) {
            SettingsLink(label: {
                Text("Settings")
            })
            .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
            Divider()
            Button("Quit", role: .destructive) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut(KeyEquivalent("Q"), modifiers: .command)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    let vm: BoringViewModel = .init()
    var window: NSWindow!
    let manager: HUDManager

    lazy var changesObserver = ChangesObserver(manager: manager)
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    override init() {
        manager = HUDManager(vm: vm)
        super.init()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        OSDUIManager.removeSystemEventMonitoring()
        OSDUIManager.start()
        NSLog("Target app is terminating")
        NotificationCenter.default.removeObserver(self)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        vm.setupWorkerNotifiers()
        
        NSApp.setActivationPolicy(.accessory)
        
        DispatchQueue.main.async {
            self.setupWindow()
        }

        changesObserver.startObserving()

        // Enhanced OSD management with system event monitoring
        OSDUIManager.setupSystemEventMonitoring()
        OSDUIManager.stop()
        
        if let containerID = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] {
            print("Sandbox is enabled. Container ID: \(containerID)")
        } else {
            print("Sandbox is not enabled.")
        }
    }
    
    private func setupWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        
        window.contentView = NSHostingView(rootView: ContentView().environmentObject(vm))
    }
    
    @objc func showMenu() {
        statusItem!.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
    
    @objc func quitAction() {
        NSApplication.shared.terminate(nil)

    }
}
