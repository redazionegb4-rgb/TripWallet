import Foundation
import SwiftUI

@MainActor
final class TravelStore: ObservableObject {
    @Published var trips: [Trip] = [] { didSet { save() } }
    @Published var selectedTripID: UUID?
    private let fileURL: URL
    private var isLoading = true

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("TripWallet", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("travelwallet.json")
        load()
        isLoading = false
    }

    var upcomingTrips: [Trip] { trips.filter { $0.endDate >= Calendar.current.startOfDay(for: Date()) }.sorted { $0.startDate < $1.startDate } }
    var pastTrips: [Trip] { trips.filter { $0.endDate < Calendar.current.startOfDay(for: Date()) }.sorted { $0.endDate > $1.endDate } }

    func add(_ trip: Trip) { trips.append(trip) }
    func delete(at offsets: IndexSet, from list: [Trip]) {
        let ids = offsets.map { list[$0].id }
        trips.removeAll { ids.contains($0.id) }
    }
    func update(_ trip: Trip) { if let i = trips.firstIndex(where: { $0.id == trip.id }) { trips[i] = trip } }
    func tripBinding(_ id: UUID) -> Binding<Trip>? {
        guard let index = trips.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(get: { self.trips[index] }, set: { self.trips[index] = $0 })
    }

    private func save() {
        guard !isLoading else { return }
        do {
            let data = try JSONEncoder.travel.encode(trips)
            try data.write(to: fileURL, options: .atomic)
        } catch { print("Save error: \(error)") }
    }
    private func load() {
        guard let data = try? Data(contentsOf: fileURL), let decoded = try? JSONDecoder.travel.decode([Trip].self, from: data) else { return }
        trips = decoded
    }

    func exportData() throws -> URL {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("TripWallet-Backup-\(ISO8601DateFormatter().string(from: Date()).prefix(10)).travelwallet")
        try JSONEncoder.travel.encode(trips).write(to: temp, options: .atomic)
        return temp
    }
    func importData(from url: URL) throws {
        let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
        let decoded = try JSONDecoder.travel.decode([Trip].self, from: Data(contentsOf: url))
        trips = decoded
    }
    func saveToICloud() throws -> URL {
        guard let ubiquity = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { throw BackupError.iCloudUnavailable }
        let docs = ubiquity.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        let target = docs.appendingPathComponent("TripWallet-Backup.travelwallet")
        try JSONEncoder.travel.encode(trips).write(to: target, options: .atomic)
        return target
    }
    func restoreFromICloud() throws {
        guard let ubiquity = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { throw BackupError.iCloudUnavailable }
        let target = ubiquity.appendingPathComponent("Documents/TripWallet-Backup.travelwallet")
        trips = try JSONDecoder.travel.decode([Trip].self, from: Data(contentsOf: target))
    }
}

enum BackupError: LocalizedError { case iCloudUnavailable; var errorDescription: String? { "iCloud non è disponibile. Attiva iCloud Drive e configura il container dell’app in Xcode." } }

extension JSONEncoder { static var travel: JSONEncoder { let e=JSONEncoder(); e.dateEncodingStrategy = .iso8601; e.outputFormatting = [.prettyPrinted, .sortedKeys]; return e } }
extension JSONDecoder { static var travel: JSONDecoder { let d=JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d } }
