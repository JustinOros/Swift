import SwiftUI

@main
struct HamOperatorQuizApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TestSelectionView()
            }
            .frame(minWidth: 300, minHeight: 200)
        }
    }
}
