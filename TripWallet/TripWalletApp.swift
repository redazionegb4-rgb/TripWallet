import SwiftUI

@main
struct TripWalletApp: App {
    @StateObject private var store = TravelStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if store.account.isAuthenticated {
                    RootView()
                } else {
                    AuthenticationView()
                }
            }
            .environmentObject(store)
        }
    }
}
