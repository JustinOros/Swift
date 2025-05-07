//
//  ContentView.swift
//  Speedometer
//
//  Created by Justin Oros on 5/2/2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager() // 📍 Handles GPS updates

    // 🚗 Speed unit toggle (true = MPH, false = KPH), persisted
    @State private var isMPH: Bool = UserDefaults.standard.object(forKey: "SpeedUnitIsMPH") as? Bool ?? true

    @State private var previousLocation: CLLocation? // 📌 Last location to calculate distance
    @State private var tripDistanceMeters: Double = 0.0 // 📏 Distance in meters

    // 🌗 Theme (persisted)
    @State private var isDarkMode: Bool = UserDefaults.standard.bool(forKey: "DarkModeEnabled")

    // 👁️ Minimal view toggle (persisted)
    @State private var isMinimalView: Bool = UserDefaults.standard.bool(forKey: "MinimalViewEnabled")

    // 🧠 Load saved trip distance
    init() {
        if let savedDistance = UserDefaults.standard.object(forKey: "TripDistance") as? Double {
            _tripDistanceMeters = State(initialValue: savedDistance)
        }
    }

    // 🧮 Current speed in selected unit
    var currentSpeed: Int {
        let multiplier = isMPH ? 1.0 : 1.60934
        return Int(Double(locationManager.speed) * multiplier)
    }

    // 🏷️ Speed unit label
    var unitLabel: String {
        isMPH ? "mph" : "kph"
    }

    // 📐 Trip distance display
    var distanceLabel: String {
        let distance = isMPH ? tripDistanceMeters * 0.000621371 : tripDistanceMeters / 1000
        let roundedDistance = Int(distance.rounded())
        return "\(roundedDistance) \(isMPH ? "miles" : "km")"
    }

    // 🎯 Color based on GPS accuracy
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

    // 🎨 Theme-dependent UI colors
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

                // 🔢 Speed and unit toggle
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(currentSpeed)")
                        .font(.system(size: 140, weight: .bold, design: .rounded))
                        .foregroundColor(foregroundColor)

                    Text(unitLabel)
                        .font(.title2)
                        .foregroundColor(secondaryTextColor)
                        .onTapGesture {
                            isMPH.toggle()
                            UserDefaults.standard.set(isMPH, forKey: "SpeedUnitIsMPH") // 💾 Save unit preference
                        }
                }

                if !isMinimalView {
                    // 📊 Trip distance + reset
                    HStack(spacing: 8) {
                        Text("Trip: \(distanceLabel)")
                            .font(.title2)
                            .foregroundColor(secondaryTextColor)

                        Button(action: {
                            tripDistanceMeters = 0
                            previousLocation = nil
                            UserDefaults.standard.set(0.0, forKey: "TripDistance") // 🧹 Reset saved distance
                        }) {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.title2)
                                .foregroundColor(secondaryTextColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // 🎯 GPS Accuracy indicator
                    Text(String(format: "GPS Accuracy: ±%.0f meters", locationManager.accuracy))
                        .font(.headline)
                        .foregroundColor(accuracyColor)
                }

                Spacer()
            }
            .padding()

            // ⚙️ Bottom toolbar (minimal mode + settings)
            VStack {
                Spacer()
                HStack {
                    // 👁️ Toggle minimal view + persist
                    Button(action: {
                        isMinimalView.toggle()
                        UserDefaults.standard.set(isMinimalView, forKey: "MinimalViewEnabled")
                    }) {
                        Image(systemName: isMinimalView ? "eye.slash.fill" : "eye.fill")
                            .font(.title2)
                            .foregroundColor(foregroundColor)
                            .padding()
                    }

                    Spacer()

                    // ⚙️ Open system Settings
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

        // 🌗 Tap background to toggle dark/light mode and save it
        .onTapGesture {
            isDarkMode.toggle()
            UserDefaults.standard.set(isDarkMode, forKey: "DarkModeEnabled")
        }

        // 🚨 Handle location errors with alert
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

        // 🧮 Track trip distance as location updates
        .onReceive(locationManager.$location) { location in
            if let newLocation = location {
                if let oldLocation = previousLocation {
                    let distance = newLocation.distance(from: oldLocation)
                    tripDistanceMeters += distance
                    UserDefaults.standard.set(tripDistanceMeters, forKey: "TripDistance") // 💾 Save updated distance
                }
                previousLocation = newLocation
            }
        }
    }
}
