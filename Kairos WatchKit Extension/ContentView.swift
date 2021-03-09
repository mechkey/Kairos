//
//  ContentView.swift
//  Kairos WatchKit Extension
//
//  Created by Luke on 03/03/2021.
//

//
//  ContentView.swift
//  Project10 WatchKit Extension
//
//  Created by Paul Hudson on 07/10/2020.
//
import HealthKit
import SwiftUI

struct ContentView: View {

    @StateObject var dataManager = DataManager()
    @State private var selectedActivity = 0

    var body: some View {
        if dataManager.state == .inactive {
            VStack {
                
                Button("Start Workout") {
                    guard HKHealthStore.isHealthDataAvailable() else { return }
                    WKInterfaceDevice.current().play(.notification)
                    dataManager.activity = .other
                    dataManager.start()
                    
                }
            }
        } else {
            SessionView(dataManager: dataManager)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
