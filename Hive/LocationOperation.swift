//
//  LocationOperation.swift
//  Hive
//
//  Abstract:
//  This file shows how to retrieve the user's location with an operation.
//
//  Created by Animesh. on 26/10/2015.
//  Copyright © 2015 Heimdall Ltd. All rights reserved.
//

import Foundation
import CoreLocation

/**
    `LocationOperation` is an `Operation` subclass to do a "one-shot" request to
    get the user's current location, with a desired accuracy. This operation will
    prompt for `WhenInUse` location authorization, if the app does not already
    have it.
*/
class LocationOperation: Operation, CLLocationManagerDelegate {
    // MARK: Properties
    
    private let accuracy: CLLocationAccuracy
    private var manager: CLLocationManager?
    private let handler: CLLocation -> Void
    
    // MARK: Initialization
 
    init(accuracy: CLLocationAccuracy, locationHandler: CLLocation -> Void) {
        self.accuracy = accuracy
        self.handler = locationHandler
        super.init()
        addCondition(LocationCondition(usage: .WhenInUse))
        addCondition(MutuallyExclusive<CLLocationManager>())
    }
    
    override func execute() {
        dispatch_async(dispatch_get_main_queue()) {
            /*
                `CLLocationManager` needs to be created on a thread with an active
                run loop, so for simplicity we do this on the main queue.
            */
            let manager = CLLocationManager()
            manager.desiredAccuracy = self.accuracy
            manager.delegate = self
            manager.startUpdatingLocation()
            
            self.manager = manager
        }
    }
    
    override func cancel() {
        dispatch_async(dispatch_get_main_queue()) {
            self.stopLocationUpdates()
            super.cancel()
        }
    }
    
    private func stopLocationUpdates() {
        manager?.stopUpdatingLocation()
        manager = nil
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last where location.horizontalAccuracy <= accuracy else {
            return
        }
        
        stopLocationUpdates()
        handler(location)
        finish()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        stopLocationUpdates()
        finishWithError(error)
    }
}
