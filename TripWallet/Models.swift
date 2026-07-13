import Foundation

struct UserProfile: Codable, Equatable {
    var name: String = ""
    var email: String = ""
    var passwordHash: String? = nil
    var isLoggedIn: Bool = false
}

struct Trip: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var city: String
    var country: String
    var countryCode: String
    var startDate: Date
    var endDate: Date
    var notes: String = ""
    var coverImageData: Data? = nil
    var items: [TravelItem] = []
    var expenses: [Expense] = []
    var packing: [PackingItem] = []
    var places: [SavedPlace] = []
    var documents: [TravelDocument] = []

    var destination: String {
        city.isEmpty ? country : "\(city), \(country)"
    }

    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var daysCount: Int {
        max(1, (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1)
    }
}

enum TravelItemType: String, Codable, CaseIterable, Identifiable {
    case flight = "Volo"
    case hotel = "Hotel"
    case train = "Treno"
    case ferry = "Traghetto"
    case bus = "Bus"
    case activity = "Attività"
    case reminder = "Promemoria"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .flight: return "airplane"
        case .hotel: return "building.2.fill"
        case .train: return "tram.fill"
        case .ferry: return "ferry.fill"
        case .bus: return "bus.fill"
        case .activity: return "ticket.fill"
        case .reminder: return "bell.fill"
        }
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
}

enum DocumentKind: String, Codable, CaseIterable, Identifiable {
    case flight = "Carta d’imbarco"
    case hotel = "Voucher hotel"
    case train = "Biglietto treno"
    case event = "Biglietto evento"
    case insurance = "Assicurazione"
    case identity = "Documento personale"
    case other = "Altro"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .flight: return "airplane"
        case .hotel: return "building.2.fill"
        case .train: return "tram.fill"
        case .event: return "ticket.fill"
        case .insurance: return "cross.case.fill"
        case .identity: return "person.text.rectangle.fill"
        case .other: return "doc.fill"
        }
    }
}

struct TravelDocument: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var kind: DocumentKind
    var bookingCode: String = ""
    var imageData: Data? = nil
    var fileName: String? = nil
    var fileData: Data? = nil
    var notes: String = ""
}
