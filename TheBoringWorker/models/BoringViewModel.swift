//
//  BoringViewModel.swift
//  TheBoringWorker
//
//  Created by Harsh Vardhan  Goswami  on 08/09/24.
//

import Combine
import SwiftUI
import TheBoringWorkerNotifier

class BoringViewModel: NSObject, ObservableObject {
    var cancellables: Set<AnyCancellable> = []
    @Published var releaseName: String = "Oori Schubert 🥶"
    @AppStorage("showMenuBarIcon") var showMenuBarIcon: Bool = false
    var notifier: TheBoringWorkerNotifier = .init()
    
    deinit {
        destroy()
    }
    
    override init() {
        super.init()
    }
    
    func destroy() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    func setupWorkerNotifiers() {
        // you can create a new instance of WorkerNotification if you want to use a different notification
        notifier.setupObserver(notification: WorkerNotification( //add HUD management!!!
            name: "theboringteam.theboringworker.togglehudreplacement",
            handler: { _ in
                print("Received togglehudreplacement notification")
            }
        )) { Notification in
            NSLog("Notification received: \(Notification)")
        }
    }
}
