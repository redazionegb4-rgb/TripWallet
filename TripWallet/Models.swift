import Foundation

struct Trip: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var destination: String
    var countryCode: String
    var startDate: Date
    var endDate: Date
    var notes: String = ""
    var colorName: String = "blue"
    var items: [TravelItem] = []
    var expenses: [Expense] = []
    var packing: [PackingItem] = []
    var places: [SavedPlace] = []
    var documents: [TravelDocument] = []

    var totalSpent: Double { expenses.reduce(0) { $0 + $1.amount } }
    var daysCount: Int { max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1 }
}

enum TravelItemType: String, Codable, CaseIterable, Identifiable {
    case flight = "Volo", hotel = "Alloggio", train = "Treno", ferry = "Traghetto", bus = "Bus", activity = "Attività", reminder = "Promemoria"
    var id: String { rawValue }
    var icon: String {
        switch self { case .flight: "airplane"; case .hotel: "bed.double.fill"; case .train: "tram.fill"; case .ferry: "ferry.fill"; case .bus: "bus.fill"; case .activity: "ticket.fill"; case .reminder: "bell.fill" }
    }
}

struct TravelItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var type: TravelItemType
    var title: String
    var subtitle: String = ""
    var date: Date
    var endDate: Date? = nil
    var location: String = ""
    var bookingCode: String = ""
    var notes: String = ""
    var notify: Bool = false
}

struct Expense: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var amount: Double
    var category: String
    var date: Date
    var notes: String = ""
}

struct PackingItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var category: String
    var packed: Bool = false
}

struct SavedPlace: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var address: String
    var category: String
    var notes: String = ""
}

struct TravelDocument: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var type: String
    var expiryDate: Date? = nil
    var fileName: String? = nil
    var bookmarkData: Data? = nil
    var notes: String = ""
}
