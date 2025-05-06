//
//  ContentView.swift
//  Speedometer
//
//  Created by Justin Oros on 5/2/2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    // Location manager to track speed and position
    @StateObject private var locationManager = LocationManager()
    
    // Unit toggle (true = MPH, false = KPH)
    @State private var isMPH = true
    
    // For tracking total trip distance
    @State private var previousLocation: CLLocation?
    @State private var tripDistanceMeters: Double = 0.0
    
    // Dark mode toggle
    @State private var isDarkMode = true
    
    // Controls whether only speed is shown (minimal view)
    @State private var isMinimalView = false

    // Computed speed based on selected unit
    var currentSpeed: Int {
        let multiplier = isMPH ? 1.0 : 1.60934
        return Int(Double(locationManager.speed) * multiplier)
    }

    // Label for speed unit
    var unitLabel: String {
        isMPH ? "mph" : "kph"
    }

    // Distance label (formatted with appropriate unit)
    var distanceLabel: String {
        let distance = isMPH ? tripDistanceMeters * 0.000621371 : tripDistanceMeters / 1000
        let roundedDistance = Int(distance.rounded())
        return "\(roundedDistance) \(isMPH ? "miles" : "km")"
    }

    // Color indicating GPS accuracy
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

    // Text and background colors based on theme
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
            // Full-screen background color
            backgroundColor.ignoresSafeArea()

            // Main vertical layout
            VStack(spacing: 30) {
                Spacer()

                // Speed display with unit
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(currentSpeed)")
                        .font(.system(size: 140, weight: .bold, design: .rounded))
                        .foregroundColor(foregroundColor)

                    Text(unitLabel)
                        .font(.title2)
                        .foregroundColor(secondaryTextColor)
                        .onTapGesture {
                            isMPH.toggle() // Toggle between mph and kph
                        }
                }

                // Show trip info and controls only if not in minimal view
                if !isMinimalView {
                    // Trip distance
                    Text("Trip: \(distanceLabel)")
                        .font(.title2)
                        .foregroundColor(secondaryTextColor)

                    // GPS accuracy
                    Text(String(format: "GPS Accuracy: ±%.0f meters", locationManager.accuracy))
                        .font(.headline)
                        .foregroundColor(accuracyColor)

                    // Reset trip button
                    Button(action: {
                        tripDistanceMeters = 0
                        previousLocation = nil
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

            // Overlay controls (bottom corners)
            VStack {
                Spacer()
                HStack {
                    // 👁 Eye icon to toggle minimal view (bottom-left)
                    Button(action: {
                        isMinimalView.toggle()
                    }) {
                        Image(systemName: isMinimalView ? "eye.slash.fill" : "eye.fill")
                            .font(.title2)
                            .foregroundColor(foregroundColor)
                            .padding()
                    }

                    Spacer()

                    // ⚙️ Gear icon to open app settings (bottom-right)
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
        .onTapGesture {
            isDarkMode.toggle() // Toggle between light and dark mode
        }
        .alert(isPresented: $locationManager.showAlert) {
            // Show alert if location services are unavailable
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
        // Track location updates and calculate distance
        .onReceive(locationManager.$location) { location in
            if let newLocation = location {
                if let oldLocation = previousLocation {
                    let distance = newLocation.distance(from: oldLocation)
                    tripDistanceMeters += distance
                }
                previousLocation = newLocation
            }
        }
    }
}
