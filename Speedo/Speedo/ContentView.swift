//
//  ContentView.swift
//  Speedometer
//
//  Created by Justin Oros on 5/2/2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isMPH = true
    @State private var previousLocation: CLLocation?
    @State private var tripDistanceMeters: Double = 0.0

    var currentSpeed: Int {
        let multiplier = isMPH ? 1.0 : 1.60934 // Already in MPH from LocationManager
        return Int(Double(locationManager.speed) * multiplier)
    }

    var unitLabel: String {
        isMPH ? "mph" : "kph"
    }

    var distanceLabel: String {
        let distance = isMPH ? tripDistanceMeters * 0.000621371 : tripDistanceMeters / 1000
        let roundedDistance = Int(distance.rounded())
        return "\(roundedDistance) \(isMPH ? "miles" : "km")"
    }

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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Center Speed Display with Unit
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(currentSpeed)")
                        .font(.system(size: 140, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(unitLabel)
                        .font(.title2)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            isMPH.toggle()
                        }
                }

                // Trip Distance
                Text("Trip: \(distanceLabel)")
                    .font(.title2)
                    .foregroundColor(.gray)

                // GPS Accuracy Display
                Text(String(format: "GPS Accuracy: ±%.0f meters", locationManager.accuracy))
                    .font(.headline)
                    .foregroundColor(accuracyColor)

                // Reset Button (smaller width)
                Button(action: {
                    tripDistanceMeters = 0
                    previousLocation = nil
                }) {
                    Text("Reset Trip")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.gray)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()

            // Settings Button (Sprocket icon) at the bottom right with padding
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "gearshape.fill") // Sprocket icon
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .padding(.bottom, 10) // Add some bottom padding
                }
                .padding(.trailing) // Keep the trailing padding for right alignment
            }
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
