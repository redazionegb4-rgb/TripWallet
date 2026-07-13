import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }.tabItem { Label("Home", systemImage: "house.fill") }
            NavigationStack { TripsView() }.tabItem { Label("Viaggi", systemImage: "airplane.departure") }
            NavigationStack { SettingsView() }.tabItem { Label("Impostazioni", systemImage: "gearshape.fill") }
        }
        .tint(.blue)
    }
}

struct LockView: View {
    @Binding var unlocked: Bool
    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 22) {
                Image(systemName: "wallet.pass.fill").font(.system(size: 70)).foregroundStyle(.white)
                Text("TripWallet").font(.largeTitle.bold()).foregroundStyle(.white)
                Button { Task { unlocked = await BiometricManager.authenticate() } } label: { Label("Sblocca", systemImage: "faceid").font(.headline).padding(.horizontal, 28).padding(.vertical, 14).background(.white).foregroundStyle(.blue).clipShape(Capsule()) }
            }
        }.task { unlocked = await BiometricManager.authenticate() }
    }
}

struct EmptyStateView: View {
    let title: String
    let icon: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 44)).foregroundStyle(.secondary)
            Text(title).font(.title3.bold())
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 34)
    }
}
