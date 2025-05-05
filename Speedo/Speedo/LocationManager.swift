//
//  LocationManager.swift
//  Speedometer
//
//  Created by Justin Oros on 5/2/2025.
//

import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var speed: Int = 0
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
        manager.distanceFilter = 1
        print("LocationManager initialized")
        requestAuthorization()
        startUpdatingLocationIfNeeded()
    }

    private func requestAuthorization() {
        print("Requesting location authorization")
        manager.requestWhenInUseAuthorization()
    }

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

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            self.authorizationStatus = status
            print("Authorization status changed: \(status.rawValue)")
            self.startUpdatingLocationIfNeeded()
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
        @unknown default:
            print("Location authorization: Unknown status")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else {
            print("No latest location found")
            return
        }

        print("New location: \(latest.coordinate.latitude), \(latest.coordinate.longitude)")
        print("Speed (m/s): \(latest.speed)")
        print("Speed (MPH): \(latest.speed * 2.23694)")
        print("Accuracy: \(latest.horizontalAccuracy)")

        DispatchQueue.main.async {
            let rawSpeed = max(latest.speed, 0)
            let mph = rawSpeed * 2.23694
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

