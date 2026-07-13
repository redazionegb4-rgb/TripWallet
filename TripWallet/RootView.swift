import SwiftUI
import CryptoKit

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

    @State private var isRegistering = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var canContinue: Bool {
        let validEmail = normalizedEmail.contains("@")
        let validPassword = password.count >= 6
        let validName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return validEmail && validPassword && (!isRegistering || validName)
    }

    var body: some View {
        ZStack {
            AppPalette.warmGradient
                .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: 360, height: 360)
                .offset(x: 150, y: -280)

            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 82))
                        .foregroundStyle(.white)
                        .padding(.top, 50)

                    Text(isRegistering ? "Crea il tuo profilo" : "Bentornato")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Registrazione locale: nessun accesso Apple e nessun account esterno.")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.88))
                        .multilineTextAlignment(.center)

                    Picker("Accesso", selection: $isRegistering) {
                        Text("Registrati").tag(true)
                        Text("Accedi").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(5)
                    .background(.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 15))

                    VStack(spacing: 14) {
                        if isRegistering {
                            TextField("Nome", text: $name)
                                .textContentType(.name)
                                .padding(17)
                                .background(.white.opacity(0.95))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }

                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(17)
                            .background(.white.opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 18))

                        SecureField("Password (almeno 6 caratteri)", text: $password)
                            .textContentType(isRegistering ? .newPassword : .password)
                            .padding(17)
                            .background(.white.opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(.red.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        submit()
                    } label: {
                        Text(isRegistering ? "Crea profilo" : "Accedi")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(.white)
                            .foregroundStyle(AppPalette.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1 : 0.55)

                    Text("Le credenziali restano sul dispositivo. I dati dei viaggi vengono salvati nel backup iCloud.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 28)
            }
        }
        .onAppear {
            if !store.profile.email.isEmpty {
                isRegistering = false
                email = store.profile.email
            }
        }
    }

    private func submit() {
        errorMessage = ""
        let hash = password.sha256

        if isRegistering {
            store.profile = UserProfile(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: normalizedEmail,
                passwordHash: hash,
                isLoggedIn: true
            )
        } else {
            guard !store.profile.email.isEmpty else {
                errorMessage = "Non esiste ancora un profilo locale. Seleziona Registrati."
                return
            }

            guard store.profile.email.lowercased() == normalizedEmail,
                  store.profile.passwordHash == hash else {
                errorMessage = "Email o password non corretti."
                return
            }

            store.profile.isLoggedIn = true
        }
    }
}

private extension String {
    var sha256: String {
        SHA256.hash(data: Data(utf8)).map { String(format: "%02x", $0) }.joined()
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
