//
//  SessionView.swift
//  Kairos
//
//  Created by Luke on 08/03/2021.
//
import Foundation
import SwiftUI

struct SessionView: View {
    enum DisplayMode {
        case heartRate
    }

    @State private var displayMode = DisplayMode.heartRate
    
    @ObservedObject var dataManager: DataManager

    var quantity: String {
        switch displayMode {

        case .heartRate:
            return String(Int(dataManager.lastHeartRate))
        }
    }

    var body: some View {
        VStack {
            Group {
                Text(quantity)
                    .font(.largeTitle)
                Text("beats / minute")
                    .textCase(.uppercase)
                    
            }

            if dataManager.state == .active {
                Button("Pause", action: dataManager.pause)
                Button("End", action: dataManager.end)
            } else {
                Button("Resume", action: dataManager.resume)
                
            }
        }
    }
}

struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView(dataManager: DataManager())
    }
}
