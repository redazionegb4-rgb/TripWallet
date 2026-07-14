import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TravelStore

    @State private var message = ""
    @State private var working = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileCard
                iCloudCard
                appInfoCard
            }
            .padding(20)
            .padding(.bottom, 20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Profilo")
        .alert(
            "TripWallet",
            isPresented: Binding(
                get: { !message.isEmpty },
                set: { newValue in
                    if !newValue { message = "" }
                }
            )
        ) {
            Button("OK", role: .cancel) { message = "" }
        } message: {
            Text(message)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 14) {
            ZStack {
                AppTheme.sunsetGradient
                Text(String(store.account.fullName.prefix(1)).uppercased())
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .frame(width: 82, height: 82)
            .clipShape(Circle())

            Text(store.account.fullName)
                .font(.title2.bold())

            Text(store.account.email)
                .foregroundStyle(.secondary)

            Button("Esci", role: .destructive) {
                store.logout()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    private var iCloudCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "icloud.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.blue)

                Text("Backup iCloud")
                    .font(.title2.bold())

                Spacer()

                statusBadge
            }

            Text("È l’unico sistema di backup dell’app. I dati locali continuano a funzionare anche se iCloud non è ancora configurato.")
                .foregroundStyle(.secondary)

            Button {
                working = true
                Task {
                    do {
                        try await store.backupToICloud()
                        message = "Backup completato su iCloud."
                    } catch {
                        message = error.localizedDescription
                    }
                    working = false
                }
            } label: {
                Label(
                    working ? "Salvataggio…" : "Esegui backup",
                    systemImage: "arrow.up.circle.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AppTheme.primaryGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 17))
            }
            .disabled(working || store.iCloudStatus() != .available)

            Button {
                working = true
                Task {
                    do {
                        try await store.restoreFromICloud()
                        message = "Backup ripristinato correttamente."
                    } catch {
                        message = error.localizedDescription
                    }
                    working = false
                }
            } label: {
                Label("Ripristina da iCloud", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(AppTheme.blue.opacity(0.12))
                    .foregroundStyle(AppTheme.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 17))
            }
            .disabled(working || store.iCloudStatus() != .available)
        }
        .padding(22)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch store.iCloudStatus() {
        case .available:
            Text("Disponibile")
                .font(.caption.bold())
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.green.opacity(0.12))
                .clipShape(Capsule())

        case .notSignedIn:
            Text("Accesso richiesto")
                .font(.caption.bold())
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.12))
                .clipShape(Capsule())

        case .notConfigured:
            Text("Da configurare")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    private var appInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TripWallet")
                .font(.headline)
            Text("Versione 3.0 • Solo iPhone")
                .foregroundStyle(.secondary)
            Text("Profilo locale, nessun account esterno.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }
}
