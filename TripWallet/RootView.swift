import SwiftUI

enum AppTheme {
    static let violet = Color(red: 0.39, green: 0.23, blue: 0.91)
    static let blue = Color(red: 0.08, green: 0.50, blue: 0.98)
    static let cyan = Color(red: 0.02, green: 0.77, blue: 0.86)
    static let coral = Color(red: 1.00, green: 0.34, blue: 0.42)
    static let yellow = Color(red: 1.00, green: 0.72, blue: 0.20)

    static let primaryGradient = LinearGradient(
        colors: [violet, blue, cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sunsetGradient = LinearGradient(
        colors: [violet, coral, yellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct RootView: View {
    @State private var showNotificationIntro = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
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
        .tint(AppTheme.violet)
        .onAppear {
            showNotificationIntro = !UserDefaults.standard.bool(
                forKey: "notificationIntroCompleted"
            )
        }
        .sheet(isPresented: $showNotificationIntro) {
            NotificationPermissionIntro(isPresented: $showNotificationIntro)
        }
    }
}

struct AuthenticationView: View {
    @EnvironmentObject private var store: TravelStore

    @State private var mode = 0
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    private var isRegistration: Bool { mode == 0 }

    private var canSubmit: Bool {
        if isRegistration {
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                email.contains("@") &&
                password.count >= 6 &&
                password == confirmPassword
        } else {
            return email.contains("@") && password.count >= 6
        }
    }

    var body: some View {
        ZStack {
            AppTheme.primaryGradient
                .ignoresSafeArea()

            Circle()
                .fill(.white.opacity(0.13))
                .frame(width: 390, height: 390)
                .offset(x: 170, y: -310)

            ScrollView {
                VStack(spacing: 22) {
                    Spacer(minLength: 46)

                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 92, height: 92)

                        Image(systemName: "airplane")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(AppTheme.violet)
                    }

                    VStack(spacing: 8) {
                        Text(isRegistration ? "Crea il tuo profilo" : "Bentornato")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Text("Profilo locale, viaggi e biglietti sempre con te.")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.86))
                            .multilineTextAlignment(.center)
                    }

                    Picker("", selection: $mode) {
                        Text("Registrati").tag(0)
                        Text("Accedi").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(5)
                    .background(.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(spacing: 14) {
                        if isRegistration {
                            AuthField(
                                title: "Nome e cognome",
                                systemImage: "person.fill",
                                text: $name
                            )
                        }

                        AuthField(
                            title: "Email",
                            systemImage: "envelope.fill",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        AuthSecureField(
                            title: "Password",
                            systemImage: "lock.fill",
                            text: $password
                        )

                        if isRegistration {
                            AuthSecureField(
                                title: "Conferma password",
                                systemImage: "lock.shield.fill",
                                text: $confirmPassword
                            )
                        }
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
                        errorMessage = ""
                        if isRegistration {
                            store.register(
                                name: name,
                                email: email,
                                password: password
                            )
                        } else if !store.login(email: email, password: password) {
                            errorMessage = "Email o password non corretti."
                        }
                    } label: {
                        Text(isRegistration ? "Crea profilo" : "Accedi")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(.white)
                            .foregroundStyle(AppTheme.violet)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.55)

                    Text("La registrazione è locale. Il backup può essere salvato soltanto su iCloud.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                        .multilineTextAlignment(.center)

                    Spacer(minLength: 46)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
}

private struct AuthField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(AppTheme.violet)
                .frame(width: 24)

            TextField(title, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
        }
        .padding(17)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct AuthSecureField: View {
    let title: String
    let systemImage: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(AppTheme.violet)
                .frame(width: 24)

            SecureField(title, text: $text)
                .textContentType(.password)
        }
        .padding(17)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct NotificationPermissionIntro: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.primaryGradient)
                        .frame(width: 128, height: 128)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(.white)
                }

                Text("Promemoria di viaggio")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))

                Text("Ricevi avvisi in italiano per voli, hotel, attività e partenze importanti.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    Task {
                        _ = await NotificationManager.shared.requestAuthorization()
                        UserDefaults.standard.set(
                            true,
                            forKey: "notificationIntroCompleted"
                        )
                        isPresented = false
                    }
                } label: {
                    Label("Attiva notifiche", systemImage: "bell.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                Button("Non ora") {
                    UserDefaults.standard.set(
                        true,
                        forKey: "notificationIntroCompleted"
                    )
                    isPresented = false
                }
                .font(.headline)
                .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(28)
        }
    }
}
