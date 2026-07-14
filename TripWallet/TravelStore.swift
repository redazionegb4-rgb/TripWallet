import Foundation
import SwiftUI
import CryptoKit

@MainActor
final class TravelStore: ObservableObject {
    @Published var account = LocalAccount() {
        didSet { saveAccount() }
    }

    @Published var trips: [Trip] = [] {
        didSet {
            guard !isLoading else { return }
            saveTrips()
        }
    }

    private var isLoading = true
    private let accountURL: URL
    private let tripsURL: URL

    init() {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("TripWalletClean", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: base,
            withIntermediateDirectories: true
        )

        accountURL = base.appendingPathComponent("account.json")
        tripsURL = base.appendingPathComponent("trips.json")

        loadAccount()
        loadTrips()
        isLoading = false
    }

    var upcomingTrips: [Trip] {
        trips
            .filter { $0.endDate >= Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.startDate < $1.startDate }
    }

    var pastTrips: [Trip] {
        trips
            .filter { $0.endDate < Calendar.current.startOfDay(for: Date()) }
            .sorted { $0.endDate > $1.endDate }
    }

    func register(name: String, email: String, password: String) {
        account = LocalAccount(
            fullName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            passwordHash: hash(password),
            isAuthenticated: true
        )
    }

    func login(email: String, password: String) -> Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard account.email == normalized, account.passwordHash == hash(password) else {
            return false
        }
        account.isAuthenticated = true
        return true
    }

    func logout() {
        account.isAuthenticated = false
    }

    func addTrip(_ trip: Trip) {
        trips.append(trip)
    }

    func deleteTrip(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
    }

    func binding(for tripID: UUID) -> Binding<Trip>? {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return nil }
        return Binding(
            get: { self.trips[index] },
            set: { self.trips[index] = $0 }
        )
    }

    private func hash(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func saveAccount() {
        guard let data = try? JSONEncoder().encode(account) else { return }
        try? data.write(to: accountURL, options: .atomic)
    }

    private func saveTrips() {
        guard let data = try? JSONEncoder.tripWallet.encode(trips) else { return }
        try? data.write(to: tripsURL, options: .atomic)
    }

    private func loadAccount() {
        guard
            let data = try? Data(contentsOf: accountURL),
            let decoded = try? JSONDecoder().decode(LocalAccount.self, from: data)
        else { return }
        account = decoded
    }

    private func loadTrips() {
        guard
            let data = try? Data(contentsOf: tripsURL),
            let decoded = try? JSONDecoder.tripWallet.decode([Trip].self, from: data)
        else { return }
        trips = decoded
    }

    func iCloudStatus() -> ICloudStatus {
        if FileManager.default.ubiquityIdentityToken == nil {
            return .notSignedIn
        }
        guard FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil else {
            return .notConfigured
        }
        return .available
    }

    func backupToICloud() async throws {
        guard iCloudStatus() == .available else {
            throw ICloudBackupError.unavailable
        }

        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            throw ICloudBackupError.unavailable
        }

        let folder = container.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        let payload = BackupPayload(
            createdAt: Date(),
            account: account,
            trips: trips
        )

        let data = try JSONEncoder.tripWallet.encode(payload)
        try data.write(
            to: folder.appendingPathComponent("TripWalletBackup.json"),
            options: .atomic
        )
    }

    func restoreFromICloud() async throws {
        guard iCloudStatus() == .available else {
            throw ICloudBackupError.unavailable
        }

        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            throw ICloudBackupError.unavailable
        }

        let url = container
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("TripWalletBackup.json")

        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder.tripWallet.decode(BackupPayload.self, from: data)

        account = payload.account
        account.isAuthenticated = true
        trips = payload.trips
    }
}

private struct BackupPayload: Codable {
    let createdAt: Date
    let account: LocalAccount
    let trips: [Trip]
}

enum ICloudStatus: Equatable {
    case available
    case notSignedIn
    case notConfigured
}

enum ICloudBackupError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Il backup iCloud non è ancora configurato per questa build. Verifica la capability iCloud Documents in Xcode."
    }
}

extension JSONEncoder {
    static var tripWallet: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var tripWallet: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
