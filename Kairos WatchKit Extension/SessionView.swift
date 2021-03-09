//
//  SessionView.swift
//  Kairos
//
//  Created by Luke on 08/03/2021.
//

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

    var unit: String {
        switch displayMode {
        case .heartRate:
            return "beats / minute"
        }
    }

    var body: some View {
        VStack {
            Group {
                Text(quantity)
                    .font(.largeTitle)
                Text(unit)
                    .textCase(.uppercase)
            }

            if dataManager.state == .active {
                Button("Pause", action: dataManager.pause)
            } else {
                Button("Resume", action: dataManager.resume)
                Button("End", action: dataManager.end)
            }
        }
    }
    
}

struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView(dataManager: DataManager())
    }
}
