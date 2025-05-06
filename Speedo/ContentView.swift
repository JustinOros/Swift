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
    @State private var isDarkMode = true // Toggle dark/light mode
    @State private var isMinimalView = false // Show only speed + unit if true

    // Load saved trip distance from UserDefaults on launch
    init() {
        if let savedDistance = UserDefaults.standard.object(forKey: "TripDistance") as? Double {
            _tripDistanceMeters = State(initialValue: savedDistance)
        }
    }

    // Current speed value, converted to MPH or KPH
    var currentSpeed: Int {
        let multiplier = isMPH ? 1.0 : 1.60934
        return Int(Double(locationManager.speed) * multiplier)
    }

    // Speed unit label
    var unitLabel: String {
        isMPH ? "mph" : "kph"
    }

    // Formatted trip distance string
    var distanceLabel: String {
        let distance = isMPH ? tripDistanceMeters * 0.000621371 : tripDistanceMeters / 1000
        let roundedDistance = Int(distance.rounded())
        return "\(roundedDistance) \(isMPH ? "miles" : "km")"
    }

    // Dynamic color based on GPS accuracy
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

                // Speed + unit
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(currentSpeed)")
                        .font(.system(size: 140, weight: .bold, design: .rounded))
                        .foregroundColor(foregroundColor)

                    Text(unitLabel)
                        .font(.title2)
                        .foregroundColor(secondaryTextColor)
                        .onTapGesture {
                            isMPH.toggle()
                        }
                }

                // Optional elements hidden in minimal mode
                if !isMinimalView {
                    // Trip distance + reset icon
                    HStack(spacing: 8) {
                        Text("Trip: \(distanceLabel)")
                            .font(.title2)
                            .foregroundColor(secondaryTextColor)

                        Button(action: {
                            tripDistanceMeters = 0
                            previousLocation = nil
                            UserDefaults.standard.set(0.0, forKey: "TripDistance") // Clear saved value
                        }) {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.title2)
                                .foregroundColor(secondaryTextColor)
                        }
                        .buttonStyle(PlainButtonStyle()) // No tap glow
                    }

                    // GPS accuracy display
                    Text(String(format: "GPS Accuracy: ±%.0f meters", locationManager.accuracy))
                        .font(.headline)
                        .foregroundColor(accuracyColor)
                }

                Spacer()
            }
            .padding()

            // Bottom toolbar
            VStack {
                Spacer()
                HStack {
                    // Minimal mode toggle (eye icon)
                    Button(action: {
                        isMinimalView.toggle()
                    }) {
                        Image(systemName: isMinimalView ? "eye.slash.fill" : "eye.fill")
                            .font(.title2)
                            .foregroundColor(foregroundColor)
                            .padding()
                    }

                    Spacer()

                    // Open app Settings
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

        // Tap background to toggle dark/light mode
        .onTapGesture {
            isDarkMode.toggle()
        }

        // Show alert when location fails
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

        // Track trip distance by accumulating changes between locations
        .onReceive(locationManager.$location) { location in
            if let newLocation = location {
                if let oldLocation = previousLocation {
                    let distance = newLocation.distance(from: oldLocation)
                    tripDistanceMeters += distance
                    UserDefaults.standard.set(tripDistanceMeters, forKey: "TripDistance") // Persist distance
                }
                previousLocation = newLocation
            }
        }
    }
}
