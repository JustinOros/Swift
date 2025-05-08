// Speedometer App for iOS
// Author: Justin Oros
// LocationManager.swift

import Foundation
import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var speedInMS: Double = 0.0
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

        requestAuthorization()
        startUpdatingLocationIfNeeded()
    }

    // Request location access permission
    private func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    // Begin location updates if permission is granted
    private func startUpdatingLocationIfNeeded() {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Location services are disabled. Please enable them in Settings."
            }
        }
    }

    // Handle changes in authorization status
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            self.authorizationStatus = status
            self.startUpdatingLocationIfNeeded()
        }

        switch status {
        case .denied:
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Location access was denied. Please enable it in Settings."
            }
        case .restricted:
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertMessage = "Location access is restricted."
            }
        default: break
        }
    }

    // Handle new location data
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last,
              latest.horizontalAccuracy >= 0,
              latest.horizontalAccuracy < 20 else { return }

        DispatchQueue.main.async {
            let rawSpeed = max(latest.speed, 0)
            self.speedInMS = rawSpeed < 0.5 ? 0 : rawSpeed
            self.location = latest
            self.accuracy = latest.horizontalAccuracy
        }
    }

    // Handle location update errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError

        // Ignore transient or non-critical errors
        if nsError.code == CLError.locationUnknown.rawValue ||
           nsError.code == CLError.network.rawValue ||
           nsError.code == CLError.denied.rawValue ||
           nsError.code == CLError.deferredFailed.rawValue {
            return
        }

        DispatchQueue.main.async {
            self.showAlert = true
            self.alertMessage = "Location update failed: \(error.localizedDescription)"
        }
    }
}
