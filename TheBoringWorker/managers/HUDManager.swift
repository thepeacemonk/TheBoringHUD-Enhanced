//
//  HUDManager.swift
//  TheBoringWorker
//
//  Created by Oori Schubert on 2/26/25.
//


import Foundation

class HUDManager: ObservableObject {
    var vm: BoringViewModel?
    
    init(vm: BoringViewModel) {
        self.vm = vm
    }
    
    struct SharedSneakPeek: Codable {
        var show: Bool
        var type: String
        var value: String
        var icon: String
    }
    
    func sendBrightnessNotification(value: Float) {
        let payload = SharedSneakPeek(
            show: true,
            type: "brightness",
            value: "\(value)",
            icon: ""
        )
        do {
            let jsonData = try JSONEncoder().encode(payload)
            vm?.notifier.postNotification(name: "theboringteam.workers.sneakPeak", userInfo: ["data": jsonData])
        } catch {
            print("Error encoding brightness payload: \(error)")
        }
    }
    
    func sendVolumeNotification(value: Float) {
        let payload = SharedSneakPeek(
            show: true,
            type: "volume",
            value: "\(value)",
            icon: ""
        )
        do {
            let jsonData = try JSONEncoder().encode(payload)
            vm?.notifier.postNotification(name: "theboringteam.workers.sneakPeak", userInfo: ["data": jsonData])
        } catch {
            print("Error encoding brightness payload: \(error)")
        }
    }

}
