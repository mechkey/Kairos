//
//  DataManager.swift
//  Kairos
//
//  Created by Luke on 08/03/2021.
//

import Foundation
import HealthKit
import WatchKit

class DataManager: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, WKExtendedRuntimeSessionDelegate {
//class DataManager: WKInterfaceController, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, WKExtendedRuntimeSessionDelegate {
    
    override init() {
        self.healthStore = HKHealthStore()
        self.restingHeartRate = nil
    }

    enum WorkoutState {
        case inactive, active, paused
    }
    
    var healthStore: HKHealthStore
    var workoutSession: HKWorkoutSession?
    var workoutBuilder: HKLiveWorkoutBuilder?
    
    var session: WKExtendedRuntimeSession!
    
    var activity = HKWorkoutActivityType.walking
    var sessionStart: Date = Date()
    var heartRateValues = [Double]()
    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
    
    let restingHeartRate: HKQuantityTypeIdentifier?
    

    @Published var state = WorkoutState.inactive
    @Published var lastHeartRate = 0.0

    func start() {
        let sampleTypes: Set<HKSampleType> = [
            // sampletype bad practice? medium.com/@Cordavi/lets-talk-about-healthkit-part-1-24e57c80903c
            .workoutType(),
            .quantityType(forIdentifier: .heartRate)!,

        ]
        print(restingHeartRate)
        healthStore.requestAuthorization(toShare: sampleTypes, read: sampleTypes) { success, error in
            if success {
                //self.beginSession()
                self.beginWorkout()
            }
        }
    }

    private func beginSession() {
        session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        print("Session started")
        guard let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            fatalError("This method should never fail")
        }
        let calendar = NSCalendar.current
        let now = Date()
        //let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        guard let startDate = calendar.date(byAdding: .hour, value: -1, to: now) else {
            fatalError("*** Unable to create start date ***")
        }
        let range = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [])
        let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: sampleType, predicate: range, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortByDate]) { query, results, error in
        

            guard let samples = results as? [HKQuantitySample] else {
                //Handle errors
                return
            }
            
            for sample in samples {
                print(sample)// Process sample
                DispatchQueue.main.async {
                    //Update UI
                    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                    self.lastHeartRate = sample.quantity.doubleValue(for: heartRateUnit)
                    
                }
            }
            
            //The results come back on an anonomyous backgorund queueu
            //Dispatch to the main queue fbefore modifing the ui
            DispatchQueue.main.async {
                //Update UI
                //self.heartRate = sample.quantity.doubleValue(for: beatsPerMinute)
                
            }
        }
        healthStore.execute(query)
        //beginWorkout()
    }

    func stopSession() {
        session.invalidate()
    }
    
    private func beginWorkout() {
        healthStore = HKHealthStore()
        let config = HKWorkoutConfiguration()
        config.activityType = activity
        config.locationType = .indoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            //workoutBuilder?.shouldCollectWorkoutEvents = false
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            

            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                guard success else {
                    return
                }

                DispatchQueue.main.async {
                    self.state = .active
                }
            }
        } catch {
            // Handle errors here
        }
    }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        // Indicates that the session has encountered an error or stopped running
    }
    
    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        sessionStart = Date()
    }
    
    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        // Track when your session ends. Also handle errors here.
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            switch toState {
            case .running:
                self.state = .active

            case .paused:
                self.state = .paused

            case .ended:
                self.save()
                self.session = nil
 
            default:
                break
            } 
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { return }
            guard let statistics = workoutBuilder.statistics(for: quantityType) else { continue }
            

            DispatchQueue.main.async {
                
                self.lastHeartRate = statistics.mostRecentQuantity()?.doubleValue(for: self.heartRateUnit) ?? 0
            }
            if lastHeartRate != 0.0 {
                heartRateValues.append(lastHeartRate)
            }
            print(heartRateValues)
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {

    }

    func pause() {
        workoutSession?.pause()
    }

    func resume() {
        workoutSession?.resume()
    }

    func end() {
        workoutSession?.end()
    }
    
    //https://www.devfright.com/a-quick-look-at-hkhealthstore/
    func save() {
        self.workoutBuilder?.endCollection(withEnd: Date()) { success, error in
            self.workoutBuilder?.finishWorkout { workout, error in
                DispatchQueue.main.async {
                    self.state = .inactive
                    //
                    self.fetchAndDelete()
                    //
                }
                
                let quantityType = HKObjectType.quantityType(forIdentifier: .heartRate)
                let beatsPerMin = HKQuantitySample.init(type: quantityType!, quantity: HKQuantity.init(unit: self.heartRateUnit, doubleValue: self.lastHeartRate), start: Date(), end: Date())
                self.healthStore.save(beatsPerMin) { (success, error) in
                    if !success {
                        print("error: \(String(describing: error))")
                    } else {
                        print("Succesfully saved")
                        self.fetchAndDelete()
                    }
                }
                
                
            }
        }
    }
    
    //https://www.devfright.com/a-quick-look-at-hkhealthstore/
    func fetchAndDelete() {
        let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
        print("set sampletype")
        print(healthStore.earliestPermittedSampleDate())
        let query = HKSampleQuery.init(sampleType: sampleType!,
                                       predicate: nil,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: nil) { (query, results, error) in
                                            for result in results! {
                                                print(result)
                                                let objectToDelete = result
                                                //let objectToDelete = results?.last
                                                //print("object to delete:")
                                                print(objectToDelete.description)
                                                self.healthStore.delete(objectToDelete) { (success, error) in
                                                //self.healthStore.delete(results!) { (success, error) in
                                                    if !success {
                                                        print("error: \(String(describing: error))")
                                                    } else {
                                                        print("Succesfully Deleted")
                                                    }
                                                }
                                            }
                                        }
        healthStore.execute(query)
    }
        
    
}

