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
    
    var RHRMultiplier = 1.15

    var notify = false
    
    
    var body: some View {
        VStack {
            //Text("AVG:" + String(format: "%f", dataManager.heartRateValueAverage))
            //Text("1.2*RHR:" + String(format: "%f", dataManager.getRestingHeartRate()*1.2))
            /*if dataManager.heartRateValueAverage < dataManager.restingHeartRate * RHRMultiplier && dataManager.heartRateValueAverage != 0.0 {
                Text("Visualise your goal")
                Button("End", action: dataManager.end)
            }*/
            if dataManager.state == .active {
                
                //Button("Pause", action: dataManager.pause)
                if dataManager.heartRateValueAverage < dataManager.restingHeartRate * Double(RHRMultiplier) && dataManager.heartRateValueAverage != 0.0  {
                    
                    Text("Visualise your goal")
                    //WKInterfaceDevice.current().play(.notification)
                } else {
                    Text("You can do this!")
                }
                Button("End", action: dataManager.end)
                
            } else {
                //Button("Resume", action: dataManager.resume)
            }
        }
    }
}


struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView(dataManager: DataManager())
    }
}

