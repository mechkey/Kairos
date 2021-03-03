//
//  KairosApp.swift
//  Kairos WatchKit Extension
//
//  Created by Luke on 03/03/2021.
//

import SwiftUI

@main
struct KairosApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
