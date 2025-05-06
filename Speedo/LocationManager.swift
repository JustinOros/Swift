//
//  LocationManager.swift
//  Speedometer
//
//  Created by Justin Oros on 5/2/2025.
//

import Foundation
import CoreLocation
import SwiftUI

/// A class responsible for managing and publishing location and speed updates.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    /// The underlying Core Location manager instance.
    private let manager = CLLocationManager()

    // MARK: - Published Properties (UI-bound)
    
    /// Current speed in MPH (calculated from CLLocation speed).
    @Published var speed: Int = 0

    /// Most recent known location.
    @Published var location: CLLocation?

    /// Horizontal accuracy in meters.
    @Published var accuracy: Double = 0.0

    /// Current authorization status.
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Flag to show alert when location permissions are problematic.
    @Published var showAlert = false

    /// Message to display in the alert.
    @Published var alertMessage = ""

    // MARK: - Initialization

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .automotiveNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 1 // Update for every meter moved

        print("LocationManager initialized")

        requestAuthorization()
        startUpdatingLocationIfNeeded()
    }

    // MARK: - Authorization

    /// Requests location permission from the user.
    private func requestAuthorization() {
        print("Requesting location authorization")
        manager.requestWhenInUseAuthorization()
    }

    /// Starts updating location only if authorization is granted.
    private func startUpdatingLocationIfNeeded() {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            print("Attempting to start location updates")
            manager.startUpdatingLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            print("Location updates not started due to denied/restricted authorization")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Location services are disabled. Please enable them in Settings."
            }
        } else {
            print("Authorization not yet determined: \(authorizationStatus.rawValue)")
        }
    }

    /// Called whenever the app's location authorization status changes.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            self.authorizationStatus = status
            print("Authorization status changed: \(status.rawValue)")
            self.startUpdatingLocationIfNeeded()
        }

        // Handle alert messaging for denied or restricted access
        switch status {
        case .authorizedAlways:
            print("Location authorization: Authorized Always")
        case .authorizedWhenInUse:
            print("Location authorization: Authorized When In Use")
        case .denied:
            print("Location authorization: Denied")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Location access was denied. Please enable it in Settings for the app to function correctly."
            }
        case .restricted:
            print("Location authorization: Restricted")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Location access is restricted. This might be due to parental controls or system settings."
            }
        case .notDetermined:
            print("Location authorization: Not Determined")
        @unknown default:
            print("Location authorization: Unknown status")
        }
    }

    // MARK: - Location Updates

    /// Called whenever new location data is available.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else {
            print("No latest location found")
            return
        }

        // Logging raw location data for debugging
        print("New location: \(latest.coordinate.latitude), \(latest.coordinate.longitude)")
        print("Speed (m/s): \(latest.speed)")
        print("Speed (MPH): \(latest.speed * 2.23694)")
        print("Accuracy: \(latest.horizontalAccuracy)")

        DispatchQueue.main.async {
            // Ensure speed is non-negative (as negative = invalid)
            let rawSpeed = max(latest.speed, 0)
            
            // Convert from meters per second to MPH
            let mph = rawSpeed * 2.23694
            
            // Update published properties to refresh UI
            self.speed = Int(mph.rounded())
            self.location = latest
            self.accuracy = latest.horizontalAccuracy
        }
    }

    /// Called when location updates fail.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.showAlert = true
            self.alertMessage = "Location update failed: \(error.localizedDescription)"
        }
    }
}
