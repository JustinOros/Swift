import SwiftUI

struct TestSelectionView: View {
    let testOptions = ["Technician Class", "General Class", "Extra Class"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()  // Push content down for vertical centering
                
                ForEach(testOptions, id: \.self) { test in
                    NavigationLink(value: test) {
                        Text(test)
                            .frame(width: 250, height: 50)
                            .background(Color.blue.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                Link("Find an Exam Center", destination: URL(string: "https://www.arrl.org/find-an-amateur-radio-license-exam-session")!)
                    .foregroundColor(.blue)
                    .padding(.top, 20)

                Spacer()  // Push content up for vertical centering
            }
            .navigationTitle("Select Test")
            .navigationDestination(for: String.self) { selectedTest in
                QuizView(testName: selectedTest.replacingOccurrences(of: " Class", with: ""))
            }
            .padding()
        }
    }
}
