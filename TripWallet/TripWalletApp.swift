import SwiftUI

@main
struct TripWalletApp: App {
    @StateObject private var store = TravelStore()
    @State private var showNotificationIntro = false

    var body: some Scene {
        WindowGroup {
            Group {
                if store.profile.isLoggedIn {
                    RootView()
                        .sheet(isPresented: $showNotificationIntro) {
                            NotificationIntroView(isPresented: $showNotificationIntro)
                        }
                        .onAppear {
                            showNotificationIntro = !UserDefaults.standard.bool(
                                forKey: "notificationIntroSeen"
                            )
                        }
                } else {
                    LoginView()
                }
            }
            .environmentObject(store)
        }
    }
}
