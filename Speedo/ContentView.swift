//
//  ContentView.swift
//  Speedometer
//
//  Created by Justin Oros on 5/2/2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager() // Manages live GPS data
    @State private var isMPH = true // Toggle between MPH and KPH
    @State private var previousLocation: CLLocation?
    @State private var tripDistanceMeters: Double = 0.0 // Trip distance in meters
    @State private var isDarkMode = true // Theme toggle: dark/light
    @State private var isMinimalView = false // Toggle minimal UI showing only speed

    // Load saved trip distance when the view is initialized (even before body runs)
    init() {
        if let savedDistance = UserDefaults.standard.object(forKey: "TripDistance") as? Double {
            _tripDistanceMeters = State(initialValue: savedDistance)
        }
    }

    // Current speed converted to either MPH or KPH
    var currentSpeed: Int {
        let multiplier = isMPH ? 1.0 : 1.60934
        return Int(Double(locationManager.speed) * multiplier)
    }

    // Display correct unit
    var unitLabel: String {
        isMPH ? "mph" : "kph"
    }

    // Display formatted trip distance
    var distanceLabel: String {
        let distance = isMPH ? tripDistanceMeters * 0.000621371 : tripDistanceMeters / 1000
        let roundedDistance = Int(distance.rounded())
        return "\(roundedDistance) \(isMPH ? "miles" : "km")"
    }

    // Color based on GPS accuracy
    var accuracyColor: Color {
        switch locationManager.accuracy {
        case ..<10:
            return .green
        case 10..<30:
            return .orange
        default:
            return .red
        }
    }

    // Theme-based color helpers
    var foregroundColor: Color {
        isDarkMode ? .white : .black
    }

    var secondaryTextColor: Color {
        isDarkMode ? .gray : .gray
    }

    var backgroundColor: Color {
        isDarkMode ? .black : .white
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Speed value and unit
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(currentSpeed)")
                        .font(.system(size: 140, weight: .bold, design: .rounded))
                        .foregroundColor(foregroundColor)

                    Text(unitLabel)
                        .font(.title2)
                        .foregroundColor(secondaryTextColor)
                        .onTapGesture {
                            isMPH.toggle() // Tap to switch between MPH/KPH
                        }
                }

                // Extra details (hidden in minimal mode)
                if !isMinimalView {
                    Text("Trip: \(distanceLabel)")
                        .font(.title2)
                        .foregroundColor(secondaryTextColor)

                    Text(String(format: "GPS Accuracy: ±%.0f meters", locationManager.accuracy))
                        .font(.headline)
                        .foregroundColor(accuracyColor)

                    // Reset trip button clears distance and saved value
                    Button(action: {
                        tripDistanceMeters = 0
                        previousLocation = nil
                        UserDefaults.standard.set(0.0, forKey: "TripDistance") // Clear persistence
                    }) {
                        Text("Reset Trip")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(secondaryTextColor)
                            .foregroundColor(backgroundColor)
                            .cornerRadius(12)
                    }
                }

                Spacer()
            }
            .padding()

            // Bottom control buttons
            VStack {
                Spacer()
                HStack {
                    // Toggle minimal/full view
                    Button(action: {
                        isMinimalView.toggle()
                    }) {
                        Image(systemName: isMinimalView ? "eye.slash.fill" : "eye.fill")
                            .font(.title2)
                            .foregroundColor(foregroundColor)
                            .padding()
                    }

                    Spacer()

                    // Open device Settings
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(foregroundColor)
                            .padding()
                    }
                }
                .padding([.leading, .trailing, .bottom], 10)
            }
        }

        // Tap anywhere to toggle dark/light mode
        .onTapGesture {
            isDarkMode.toggle()
        }

        // Show alert if permissions or GPS fail
        .alert(isPresented: $locationManager.showAlert) {
            Alert(
                title: Text("Location Services"),
                message: Text(locationManager.alertMessage),
                dismissButton: .default(Text("Settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }

        // Update trip distance whenever a new location is received
        .onReceive(locationManager.$location) { location in
            if let newLocation = location {
                if let oldLocation = previousLocation {
                    let distance = newLocation.distance(from: oldLocation)
                    tripDistanceMeters += distance

                    // Save updated trip distance
                    UserDefaults.standard.set(tripDistanceMeters, forKey: "TripDistance")
                }
                previousLocation = newLocation
            }
        }
    }
}
