import SwiftUI
import UserNotifications

@main
struct TripWalletApp: App {
    @StateObject private var store = TravelStore()
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("lockEnabled") private var lockEnabled = false
    @State private var unlocked = false

    var body: some Scene {
        WindowGroup {
            Group {
                if lockEnabled && !unlocked {
                    LockView(unlocked: $unlocked)
                } else {
                    RootView()
                        .environmentObject(store)
                }
            }
            .preferredColorScheme(colorScheme)
            .task {
                await NotificationManager.shared.requestAuthorization()
                if !lockEnabled { unlocked = true }
            }
        }
    }

    private var colorScheme: ColorScheme? {
        appearance == "light" ? .light : appearance == "dark" ? .dark : nil
    }
}
