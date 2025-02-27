//
//  DisplayManager.swift
//  SlimHUD
//
//  Created by Alex Perathoner on 24/12/22.
//

import Foundation
import Cocoa

class DisplayManager {
    private init() {}

    private static var useM1DisplayBrightnessMethod = false

    private static var method = SensorMethod.standard

    static func getDisplayBrightness() throws -> Float {
        switch DisplayManager.method {
        case .standard:
            do {
                return try getStandardDisplayBrightness()
            } catch {
                method = .m1
            }
        case .m1:
            do {
                return try getM1DisplayBrightness()
            } catch {
                method = .allFailed
            }
        case .allFailed:
            throw SensorError.Display.notFound
        }
        return try getDisplayBrightness()
    }

    private static func getStandardDisplayBrightness() throws -> Float {
        var brightness: float_t = 1
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        defer {
            IOObjectRelease(service)
        }

        let result = IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
        if result != kIOReturnSuccess {
            throw SensorError.Display.notStandard
        }
        return brightness
    }
    private static func getM1DisplayBrightness() throws -> Float {
        let task = Process()
        task.launchPath = "/usr/libexec/corebrightnessdiag"
        task.arguments = ["status-info"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? NSDictionary,
           let displays = plist["CBDisplays"] as? [String: [String: Any]] {
            for display in displays.values {
                if let displayInfo = display["Display"] as? [String: Any],
                    displayInfo["DisplayServicesIsBuiltInDisplay"] as? Bool == true,
                    let brightness = displayInfo["DisplayServicesBrightness"] as? Float {
                        return brightness
                }
            }
        }
        throw SensorError.Display.notSilicon
    }

    /* Note the difference between NSScreen.main and NSScreen.screens[0]:
     * NSScreen.main is the "key" screen, where the currently frontmost window resides.
     * NSScreen.screens[0] is the screen which has a menu bar, and is chosen in the Preferences > monitor settings
     */

}
