import Foundation
import SwiftUI

@MainActor
final class TravelStore: ObservableObject {
    @Published var trips: [Trip] = [] {
        didSet {
            guard !isLoading else { return }
            saveLocal()
            Task { try? await saveToICloud() }
        }
    }

    @Published var profile: UserProfile = UserProfile() {
        didSet { saveProfile() }
    }

    private let localURL: URL
    private let profileURL: URL
    private var isLoading = true

    init() {
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("TripWallet", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        localURL = directory.appendingPathComponent("trips.json")
        profileURL = directory.appendingPathComponent("profile.json")

        loadLocal()
        loadProfile()
        isLoading = false

        Task {
            try? await restoreFromICloudIfNewer()
        }
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

    func add(_ trip: Trip) {
        trips.append(trip)
    }

    func update(_ trip: Trip) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[index] = trip
    }

    func delete(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
    }

    func binding(for id: UUID) -> Binding<Trip>? {
        guard let index = trips.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.trips[index] },
            set: { self.trips[index] = $0 }
        )
    }

    private func saveLocal() {
        guard let data = try? JSONEncoder.tripWallet.encode(trips) else { return }
        try? data.write(to: localURL, options: .atomic)
    }

    private func loadLocal() {
        guard
            let data = try? Data(contentsOf: localURL),
            let decoded = try? JSONDecoder.tripWallet.decode([Trip].self, from: data)
        else { return }
        trips = decoded
    }

    private func saveProfile() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        try? data.write(to: profileURL, options: .atomic)
    }

    private func loadProfile() {
        guard
            let data = try? Data(contentsOf: profileURL),
            let decoded = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return }
        profile = decoded
    }

    private func iCloudURL() throws -> URL {
        guard let container = FileManager.default.url(
            forUbiquityContainerIdentifier: nil
        ) else {
            throw ICloudError.notAvailable
        }

        let documents = container.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(
            at: documents,
            withIntermediateDirectories: true
        )
        return documents.appendingPathComponent("TripWallet-iCloud.json")
    }

    func saveToICloud() async throws {
        let url = try iCloudURL()
        let payload = CloudPayload(updatedAt: Date(), trips: trips, profile: profile)
        let data = try JSONEncoder.tripWallet.encode(payload)
        try data.write(to: url, options: .atomic)
    }

    func restoreFromICloud() async throws {
        let url = try iCloudURL()
        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder.tripWallet.decode(CloudPayload.self, from: data)
        trips = payload.trips
        profile = payload.profile
    }

    private func restoreFromICloudIfNewer() async throws {
        let url = try iCloudURL()
        guard let data = try? Data(contentsOf: url) else { return }
        let payload = try JSONDecoder.tripWallet.decode(CloudPayload.self, from: data)

        let values = try? localURL.resourceValues(forKeys: [.contentModificationDateKey])
        let localDate = values?.contentModificationDate ?? .distantPast

        if payload.updatedAt > localDate {
            trips = payload.trips
            profile = payload.profile
        }
    }
}

private struct CloudPayload: Codable {
    var updatedAt: Date
    var trips: [Trip]
    var profile: UserProfile
}

enum ICloudError: LocalizedError {
    case notAvailable

    var errorDescription: String? {
        "iCloud non è disponibile. Accedi a iCloud sull’iPhone e attiva iCloud Drive."
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
