import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TravelStore
    @State private var message = ""
    @State private var isWorking = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                profileCard
                iCloudCard
                infoCard
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Profilo")
        .alert("TripWallet", isPresented: Binding(
            get: { !message.isEmpty },
            set: { if !$0 { message = "" } }
        )) {
            Button("OK", role: .cancel) { message = "" }
        } message: {
            Text(message)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 14) {
            ZStack {
                AppPalette.warmGradient
                Text(store.profile.name.prefix(1).uppercased())
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)
            }
            .frame(width: 82, height: 82)
            .clipShape(Circle())

            Text(store.profile.name)
                .font(.title2.bold())
            Text(store.profile.email)
                .foregroundStyle(.secondary)

            Button("Esci dal profilo", role: .destructive) {
                store.profile = UserProfile()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private var iCloudCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Backup iCloud", systemImage: "icloud.fill")
                .font(.title2.bold())
                .foregroundStyle(AppPalette.blue)

            Text("TripWallet salva automaticamente viaggi, biglietti e profilo su iCloud. Non sono presenti backup manuali o altri servizi.")
                .foregroundStyle(.secondary)

            Button {
                isWorking = true
                Task {
                    do {
                        try await store.saveToICloud()
                        message = "Backup iCloud completato."
                    } catch {
                        message = error.localizedDescription
                    }
                    isWorking = false
                }
            } label: {
                Label(
                    isWorking ? "Salvataggio…" : "Esegui backup ora",
                    systemImage: "arrow.up.circle.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AppPalette.gradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .disabled(isWorking)

            Button {
                isWorking = true
                Task {
                    do {
                        try await store.restoreFromICloud()
                        message = "Dati ripristinati da iCloud."
                    } catch {
                        message = error.localizedDescription
                    }
                    isWorking = false
                }
            } label: {
                Label("Ripristina da iCloud", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(AppPalette.blue.opacity(0.12))
                    .foregroundStyle(AppPalette.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .disabled(isWorking)
        }
        .padding(22)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TripWallet")
                .font(.headline)
            Text("Versione 2.0 • Solo iPhone")
                .foregroundStyle(.secondary)
            Text("I dati restano sul dispositivo e nel tuo account iCloud.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}
