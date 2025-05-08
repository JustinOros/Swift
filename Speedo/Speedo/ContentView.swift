// Speedometer App for iOS
// Author: Justin Oros
// ContentView.swift

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()

    // App storage settings
    @AppStorage("SpeedUnitIsMPH") private var isMPH: Bool = true
    @AppStorage("DarkModeEnabled") private var isDarkMode: Bool = true // Default to dark mode
    @AppStorage("MinimalViewEnabled") private var isMinimalView: Bool = false
    @AppStorage("TripDistance") private var tripDistanceMeters: Double = 0.0

    @State private var previousLocation: CLLocation?

    // Converts speed in m/s to selected unit
    var currentSpeed: Int {
        let speedMS = locationManager.speedInMS
        let converted = isMPH ? speedMS * 2.23694 : speedMS * 3.6
        return Int(converted.rounded())
    }

    // Returns unit label string
    var unitLabel: String {
        isMPH ? "mph" : "kph"
    }

    // Converts and formats trip distance string
    var distanceLabel: String {
        let distance = isMPH ? tripDistanceMeters * 0.000621371 : tripDistanceMeters / 1000
        return "\(Int(distance.rounded())) \(isMPH ? "miles" : "km")"
    }

    // Determines color based on GPS accuracy
    var accuracyColor: Color {
        switch locationManager.accuracy {
        case ..<10: return .green
        case 10..<30: return .orange
        default: return .red
        }
    }

    // UI colors
    var foregroundColor: Color {
        isDarkMode ? .white : .black
    }

    var secondaryTextColor: Color {
        .gray
    }

    var backgroundColor: Color {
        isDarkMode ? .black : .white
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Main speed display
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

                if !isMinimalView {
                    // Trip distance and reset button
                    HStack(spacing: 8) {
                        Text("Trip: \(distanceLabel)")
                            .font(.title2)
                            .foregroundColor(secondaryTextColor)

                        Button(action: {
                            tripDistanceMeters = 0
                            previousLocation = nil
                        }) {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.title2)
                                .foregroundColor(secondaryTextColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // GPS accuracy display
                    Text(String(format: "GPS Accuracy: ±%.0f meters", locationManager.accuracy))
                        .font(.headline)
                        .foregroundColor(accuracyColor)
                } else if locationManager.accuracy == 0 {
                    Text("Waiting for GPS...")
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding()

            // Toggle buttons
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

                    // Open app settings
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
            isDarkMode.toggle()
        }
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
        // Update trip distance with each valid location update
        .onReceive(locationManager.$location) { location in
            if let newLocation = location,
               newLocation.speed > 0.5,
               newLocation.horizontalAccuracy < 20 {
                if let oldLocation = previousLocation {
                    let distance = newLocation.distance(from: oldLocation)
                    tripDistanceMeters += distance
                }
                previousLocation = newLocation
            }
        }
    }
}

