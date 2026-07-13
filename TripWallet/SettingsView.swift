import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: TravelStore
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("lockEnabled") private var lockEnabled = false

    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var showImporter = false
    @State private var message = ""
    @State private var showMessage = false

    var body: some View {
        Form {
            Section("Aspetto") {
                Picker("Tema", selection: $appearance) {
                    Text("Automatico").tag("system")
                    Text("Chiaro").tag("light")
                    Text("Scuro").tag("dark")
                }
            }

            Section("Privacy") {
                Toggle(isOn: $lockEnabled) {
                    Label("Proteggi con Face ID", systemImage: "faceid")
                }
            }

            Section("Backup") {
                Button(action: exportBackup) {
                    Label("Esporta backup", systemImage: "square.and.arrow.up")
                }

                Button {
                    showImporter = true
                } label: {
                    Label("Importa backup", systemImage: "square.and.arrow.down")
                }

                Button(action: saveICloudBackup) {
                    Label("Salva su iCloud Drive", systemImage: "icloud.and.arrow.up")
                }

                Button(action: restoreICloudBackup) {
                    Label("Ripristina da iCloud Drive", systemImage: "icloud.and.arrow.down")
                }
            }

            Section("Informazioni") {
                LabeledContent("Versione", value: "1.0 (Build 7)")
                LabeledContent("Archiviazione", value: "Locale e offline")
                Text("TripWallet non richiede registrazione e non invia i dati a server esterni.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Impostazioni")
        .sheet(isPresented: $showShareSheet) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [UTType(filenameExtension: "travelwallet") ?? .data, .json]
        ) { result in
            do {
                let url = try result.get()
                try store.importData(from: url)
                message = "Backup importato correttamente."
            } catch {
                message = error.localizedDescription
            }
            showMessage = true
        }
        .alert("TripWallet", isPresented: $showMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(message)
        }
    }

    private func exportBackup() {
        do {
            exportURL = try store.exportData()
            showShareSheet = true
        } catch {
            message = error.localizedDescription
            showMessage = true
        }
    }

    private func saveICloudBackup() {
        do {
            _ = try store.saveToICloud()
            message = "Backup salvato su iCloud Drive."
        } catch {
            message = error.localizedDescription
        }
        showMessage = true
    }

    private func restoreICloudBackup() {
        do {
            try store.restoreFromICloud()
            message = "Backup iCloud ripristinato."
        } catch {
            message = error.localizedDescription
        }
        showMessage = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) { }
}
