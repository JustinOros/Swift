//
//  ContentView.swift
//  Speedometer
//
//  Created by Justin Oros on 5/2/2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager() // 📍 Manages real-time GPS data

    @State private var isMPH = true // 🚗 Speed unit toggle: true = MPH, false = KPH
    @State private var previousLocation: CLLocation? // 📌 Track last known location to compute trip distance
    @State private var tripDistanceMeters: Double = 0.0 // 📏 Track trip distance in meters

    // 🌗 Track current theme (loaded from UserDefaults)
    @State private var isDarkMode: Bool = UserDefaults.standard.bool(forKey: "DarkModeEnabled")

    // 👁️ Track minimal view preference (loaded from UserDefaults)
    @State private var isMinimalView: Bool = UserDefaults.standard.bool(forKey: "MinimalViewEnabled")

    // 🧠 Load trip distance if saved
    init() {
        if let savedDistance = UserDefaults.standard.object(forKey: "TripDistance") as? Double {
            _tripDistanceMeters = State(initialValue: savedDistance)
        }
    }

    // 🧮 Calculate speed based on unit selection
    var currentSpeed: Int {
        let multiplier = isMPH ? 1.0 : 1.60934
        return Int(Double(locationManager.speed) * multiplier)
    }

    // 🏷️ Speed unit label
    var unitLabel: String {
        isMPH ? "mph" : "kph"
    }

    // 📐 Distance label (miles or km)
    var distanceLabel: String {
        let distance = isMPH ? tripDistanceMeters * 0.000621371 : tripDistanceMeters / 1000
        let roundedDistance = Int(distance.rounded())
        return "\(roundedDistance) \(isMPH ? "miles" : "km")"
    }

    // 🎯 Color indicator for GPS accuracy
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

    // 🎨 Theme-dependent color helpers
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

                // ⏩ Speed display and unit toggle
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(currentSpeed)")
                        .font(.system(size: 140, weight: .bold, design: .rounded))
                        .foregroundColor(foregroundColor)

                    Text(unitLabel)
                        .font(.title2)
                        .foregroundColor(secondaryTextColor)
                        .onTapGesture {
                            isMPH.toggle() // 🔁 Tap to switch MPH/KPH
                        }
                }

                // 📊 Only show details if not in minimal mode
                if !isMinimalView {
                    // Trip meter + reset icon
                    HStack(spacing: 8) {
                        Text("Trip: \(distanceLabel)")
                            .font(.title2)
                            .foregroundColor(secondaryTextColor)

                        Button(action: {
                            tripDistanceMeters = 0
                            previousLocation = nil
                            UserDefaults.standard.set(0.0, forKey: "TripDistance") // 🧹 Clear saved trip
                        }) {
                            Image(systemName: "arrow.counterclockwise.circle") // 🔄 Reset icon
                                .font(.title2)
                                .foregroundColor(secondaryTextColor)
                        }
                        .buttonStyle(PlainButtonStyle()) // Remove button glow
                    }

                    // GPS accuracy indicator
                    Text(String(format: "GPS Accuracy: ±%.0f meters", locationManager.accuracy))
                        .font(.headline)
                        .foregroundColor(accuracyColor)
                }

                Spacer()
            }
            .padding()

            // ⚙️ Bottom control bar (eye + gear)
            VStack {
                Spacer()
                HStack {
                    // 👁️ Minimal view toggle
                    Button(action: {
                        isMinimalView.toggle()
                        UserDefaults.standard.set(isMinimalView, forKey: "MinimalViewEnabled") // 💾 Save preference
                    }) {
                        Image(systemName: isMinimalView ? "eye.slash.fill" : "eye.fill")
                            .font(.title2)
                            .foregroundColor(foregroundColor)
                            .padding()
                    }

                    Spacer()

                    // ⚙️ Open system settings
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

        // 🌗 Tap anywhere to toggle dark/light mode and save it
        .onTapGesture {
            isDarkMode.toggle()
            UserDefaults.standard.set(isDarkMode, forKey: "DarkModeEnabled") // 💾 Save theme mode
        }

        // 🚨 Show alert for location errors or denied permissions
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

        // 🧮 Update trip distance as new GPS data comes in
        .onReceive(locationManager.$location) { location in
            if let newLocation = location {
                if let oldLocation = previousLocation {
                    let distance = newLocation.distance(from: oldLocation)
                    tripDistanceMeters += distance
                    UserDefaults.standard.set(tripDistanceMeters, forKey: "TripDistance") // 💾 Save new trip value
                }
                previousLocation = newLocation
            }
        }
    }
}
