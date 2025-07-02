import SwiftUI

struct TestSelectionView: View {
    let testOptions = ["Technician Class", "General Class", "Extra Class"]

    var body: some View {
        VStack {
            List(testOptions, id: \.self) { test in
                NavigationLink(value: test) {
                    Text(test)
                }
            }
            .navigationTitle("Select Test")
            .navigationDestination(for: String.self) { selectedTest in
                QuizView(testName: selectedTest.replacingOccurrences(of: " Class", with: ""))
            }
            .frame(minWidth: 400, minHeight: 300)

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .padding(.bottom, 10)
        }
    }
}
