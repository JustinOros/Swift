//
//  LocationManager.swift
//  Speedometer
//
//  Created by Justin Oros on 5/2/2025.
//

import Foundation
import CoreLocation
import SwiftUI // Import SwiftUI for Alert

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var speed: Int = 0    // MPH as whole number
    @Published var location: CLLocation?
    @Published var accuracy: Double = 0.0
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var showAlert = false
    @Published var alertMessage = ""

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .automotiveNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 1    // Update on movement of 1 meter
        print("LocationManager initialized")
        requestAuthorization()         // Request authorization in init
        startUpdatingLocationIfNeeded() // Start updates if already authorized
    }

    private func requestAuthorization() {
        print("Requesting location authorization")
        manager.requestAlwaysAuthorization() // Request "Always" permission
    }

    private func startUpdatingLocationIfNeeded() {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            print("Attempting to start location updates")
            manager.startUpdatingLocation() // Start receiving location updates
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            print("Location updates not started due to denied/restricted authorization")
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Location services are disabled. Please enable them in Settings."
            }
        } else {
            print("Authorization not yet determined, or other status: \(authorizationStatus)")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
            print("Authorization status changed: \(status)")
            self.startUpdatingLocationIfNeeded() // Check and start updates on authorization change
        }

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
            // Authorization request will be triggered in init
            break
        @unknown default:
            print("Location authorization: Unknown status")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else {
            print("No latest location found in didUpdateLocations")
            return
        }

        // Debugging output
        print("New location received: \(latest.coordinate.latitude), \(latest.coordinate.longitude)")
        print("Speed (m/s): \(latest.speed)")
        print("Speed (MPH): \(latest.speed * 2.23694)")
        print("Accuracy: \(latest.horizontalAccuracy)")

        DispatchQueue.main.async {
            // Update speed
            let rawSpeed = max(latest.speed, 0) // Avoid negative values
            let mph = rawSpeed * 2.23694    // Convert m/s to MPH
            self.speed = Int(mph.rounded())
            self.location = latest
            self.accuracy = latest.horizontalAccuracy
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.showAlert = true
            self.alertMessage = "Location update failed: \(error.localizedDescription)"
        }
    }
}
