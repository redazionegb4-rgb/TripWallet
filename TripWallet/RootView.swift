import SwiftUI

struct AppPalette {
    static let purple = Color(red: 0.43, green: 0.24, blue: 0.96)
    static let blue = Color(red: 0.08, green: 0.55, blue: 0.98)
    static let cyan = Color(red: 0.02, green: 0.82, blue: 0.89)
    static let pink = Color(red: 0.98, green: 0.25, blue: 0.62)
    static let orange = Color(red: 1.00, green: 0.49, blue: 0.15)

    static let gradient = LinearGradient(
        colors: [purple, blue, cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [purple, pink, orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "sparkles")
            }

            NavigationStack {
                TripsView()
            }
            .tabItem {
                Label("Viaggi", systemImage: "airplane.departure")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Profilo", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(AppPalette.purple)
    }
}

struct LoginView: View {
    @EnvironmentObject private var store: TravelStore
    @State private var name = ""
    @State private var email = ""

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@")
    }

    var body: some View {
        ZStack {
            AppPalette.warmGradient
                .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: 360, height: 360)
                .offset(x: 150, y: -280)

            VStack(spacing: 22) {
                Spacer()

                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 86))
                    .foregroundStyle(.white)

                Text("Benvenuto in TripWallet")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Tutti i tuoi viaggi, biglietti e ricordi in un unico posto.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)

                VStack(spacing: 14) {
                    TextField("Nome", text: $name)
                        .textContentType(.name)
                        .padding(17)
                        .background(.white.opacity(0.94))
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding(17)
                        .background(.white.opacity(0.94))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                Button {
                    store.profile = UserProfile(
                        name: name.trimmingCharacters(in: .whitespaces),
                        email: email.trimmingCharacters(in: .whitespaces),
                        isLoggedIn: true
                    )
                } label: {
                    Text("Entra in TripWallet")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(.white)
                        .foregroundStyle(AppPalette.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.55)

                Text("Il profilo resta sul tuo dispositivo e nel tuo backup iCloud.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(28)
        }
    }
}

struct NotificationIntroView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            AppPalette.gradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 82))
                    .foregroundStyle(.white)

                Text("Non perdere partenze e check-in")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("TripWallet può ricordarti voli, hotel, attività e documenti importanti.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)

                Button {
                    Task {
                        _ = await NotificationManager.shared.requestAuthorization()
                        UserDefaults.standard.set(true, forKey: "notificationIntroSeen")
                        isPresented = false
                    }
                } label: {
                    Label("Attiva notifiche", systemImage: "bell.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(.white)
                        .foregroundStyle(AppPalette.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                Button("Non ora") {
                    UserDefaults.standard.set(true, forKey: "notificationIntroSeen")
                    isPresented = false
                }
                .foregroundStyle(.white)
                .font(.headline)

                Spacer()
            }
            .padding(28)
        }
    }
}
