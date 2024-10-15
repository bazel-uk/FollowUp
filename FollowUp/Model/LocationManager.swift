//
//  LocationManager.swift
//  FollowUp
//
//  Created by Aaron Baw on 04/10/2024.
//

import Foundation
import CoreLocation
import Combine

protocol LocationManaging: AnyObject {
    func requestAuthorisation()
    func startMonitoring()
    func stopMonitoring()
}

class LocationManager: NSObject, LocationManaging, CLLocationManagerDelegate {

    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private var followUpManager: FollowUpManager
    private var cancellables = Set<AnyCancellable>()
    
    public var authorisationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Initialization
    init(followUpManager: FollowUpManager) {
        self.followUpManager = followUpManager
        super.init()
        self.locationManager.delegate = self
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - Authorisation
    func requestAuthorisation() {
        
        guard self.followUpManager.store.settings.followUpRemindersActive else {
            Log.warn("Attempted to request authorisation for Location Monitoring but reminders are disabled in settings.")
            return
        }
        
        if ![.authorizedAlways, .authorizedWhenInUse].contains(self.authorisationStatus) {
            Log.info("Currently unauthorised to receive location updates. Requesting authorisation now.")
            self.locationManager.requestAlwaysAuthorization()
        }
    }

    // MARK: - Start/Stop Monitoring
    func startMonitoring() {
        self.requestAuthorisation()
        
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            self.locationManager.startMonitoringSignificantLocationChanges()
            Log.info("Started significant location monitoring.")
        } else {
            // Handle if significant location change monitoring is unavailable
            Log.error("Significant location change monitoring is unavailable.")
        }

    }

    func stopMonitoring() {
        self.locationManager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorisationStatus = status
        switch self.authorisationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            Log.info("Significant location change monitoring authorised.")
            self.startMonitoring()
        case .denied, .restricted:
            Log.error("Location access denied.")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Compute the number of new contacts when significant location changes occur
        Log.info("Significant location change occured. \(locations.first?.coordinate ?? .init())")
        if self.followUpManager.store.settings.followUpRemindersActive {
            self.computeContactsAndScheduleNotification()
        }
    }

    // MARK: - Compute New Contacts
    private func computeContactsAndScheduleNotification() {
        // Here, the computation logic for detecting new contacts would be called
        self.followUpManager.calculateNewlyMetContactsAndScheduleFollowUpReminderNotification()
    }
}
