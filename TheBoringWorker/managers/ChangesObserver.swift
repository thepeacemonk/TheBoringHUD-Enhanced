//
//  ChangesObserver.swift
//  SlimHUD
//
//  Created by Alex Perathoner on 24/12/22.
//

import Cocoa
import Foundation

class ChangesObserver {
    //private var oldFullScreen: Bool
    private var oldVolume: Float
    private var oldMuted: Bool
    private var oldBrightness: Float = 0
    private var oldKeyboard: Float = 0

    private var manager: HUDManager

    //private var temporarelyDisabledBars = EnabledBars(volumeBar: false, brightnessBar: false, keyboardBar: false)

    init(manager: HUDManager) {
        self.manager = manager
        oldVolume = VolumeManager.getOutputVolume()
        oldMuted = VolumeManager.isMuted()

        do {
            oldBrightness = try DisplayManager.getDisplayBrightness()
        } catch {
            NSLog("Failed to retrieve display brightness. See https://github.com/AlexPerathoner/SlimHUD/issues/60")
        }
        do {
           // oldKeyboard = try KeyboardManager.getKeyboardBrightness()
        } catch {
            NSLog("""
                Failed to retrieve keyboard brightness. Is no keyboard with backlight connected?
                Disabling keyboard HUD. If you think this is an error please report it on GitHub.
                """)
        }
    }

    func startObserving() {
        createObservers()
        createTimerForContinuousChangesCheck(with: 0.2)
    }

    private func createTimerForContinuousChangesCheck(with seconds: TimeInterval) {
        let timer = Timer(
            timeInterval: seconds, target: self, selector: #selector(checkChanges), userInfo: nil,
            repeats: true)
        let mainLoop = RunLoop.main
        mainLoop.add(timer, forMode: .common)
    }

    private func createObservers() {
//        DistributedNotificationCenter.default.addObserver(
//            self,
//            selector: #selector(showVolumeHUD),
//            name: NSNotification.Name(rawValue: "com.apple.sound.settingsChangedNotification"),
//            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showVolumeHUD),
            name: KeyPressObserver.volumeChanged,
            object: nil)
        // observers for brightness
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showBrightnessHUD),
            name: KeyPressObserver.brightnessChanged,
            object: nil)
        // observers for keyboard backlight
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(showKeyboardHUD),
//            name: KeyPressObserver.keyboardIlluminationChanged,
//            object: nil)
    }
//
    @objc func showVolumeHUD() {
        if oldVolume == 0.0 || oldVolume == 1.0 {
            manager.sendVolumeNotification(value: oldVolume)
        }
        print("showing volume")
    }
    @objc func showBrightnessHUD() {
        if oldBrightness == 0.0 || oldBrightness == 1.0 {
            manager.sendBrightnessNotification(value: oldBrightness)
        }
        print("showing brightness")
    }
    
//    @objc func showKeyboardHUD() {
//        //manager.sendKeyboardNotification(value: oldBrightness)
//    }
//
    @objc func checkChanges() {
        checkBrightnessChanges()
        checkVolumeChanges()
       // checkKeyboardChanges()
    }

    private func isAlmost(firstNumber: Float, secondNumber: Float) -> Bool {  // used to partially prevent the bars to display when no user input happened
//        return false //???
        
        let marginValue = 5 / 100.0
        return (firstNumber + Float(marginValue) >= secondNumber && firstNumber - Float(marginValue) <= secondNumber)
    }

    private func checkVolumeChanges() {
        let newVolume = VolumeManager.getOutputVolume()
        let newMuted = VolumeManager.isMuted()
        //displayer.setVolumeProgress(newVolume)
        if !isAlmost(firstNumber: oldVolume, secondNumber: newVolume) || newMuted != oldMuted {
            if newMuted {
                manager.sendVolumeNotification(value: 0.0)
            } else {
                manager.sendVolumeNotification(value: newVolume)
            }
            oldVolume = newVolume
            oldMuted = newMuted
        }
        //manager.sendVolumeNotification(value: newVolume)
    }

    private func checkBrightnessChanges() {
        if NSScreen.screens.count == 0 {
            return
        }
        do {
            let newBrightness = try DisplayManager.getDisplayBrightness()
            if !isAlmost(firstNumber: oldBrightness, secondNumber: newBrightness) {
                manager.sendBrightnessNotification(value: newBrightness)
                oldBrightness = newBrightness
            }
            //manager.sendBrightnessNotification(value: newBrightness)
        } catch {
            //temporarelyDisabledBars.brightnessBar = true
            NSLog(
                "Failed to retrieve display brightness. See https://github.com/AlexPerathoner/SlimHUD/issues/60"
            )
        }
    }

//    private func checkKeyboardChanges() {
//        do {
//            let newKeyboard = try KeyboardManager.getKeyboardBrightness()
//            if !isAlmost(firstNumber: oldKeyboard, secondNumber: newKeyboard) {
//                displayer.showKeyboardHUD()
//                oldKeyboard = newKeyboard
//            }
//            displayer.setKeyboardProgress(newKeyboard)
//        } catch {
//            temporarelyDisabledBars.keyboardBar = true
//            NSLog(
//                """
//                Failed to retrieve keyboard brightness. Is no keyboard with backlight connected? Disabling keyboard HUD.
//                If you think this is an error please report it on GitHub.
//                """)
//        }
//    }

    /// When no keyboard with backlight or display with brightness control is connected, SlimHUD fails to retrieve their values.
    ///  In fact, as they can't be controlled, they won't change. We can therefore disable those bars entirely.
    ///  However, once the display settings change, we need to reset these values.
//    public func resetTemporarelyDisabledBars() {
//        temporarelyDisabledBars = EnabledBars(
//            volumeBar: false, brightnessBar: false, keyboardBar: false)
//    }
}
