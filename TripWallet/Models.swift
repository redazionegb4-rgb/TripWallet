import Foundation

struct LocalAccount: Codable, Equatable {
    var fullName: String = ""
    var email: String = ""
    var passwordHash: String = ""
    var isAuthenticated: Bool = false
}

struct CountryOption: Identifiable, Hashable {
    let code: String
    let name: String
    var id: String { code }

    static let common: [CountryOption] = [
        .init(code: "IT", name: "Italia"),
        .init(code: "ES", name: "Spagna"),
        .init(code: "FR", name: "Francia"),
        .init(code: "PT", name: "Portogallo"),
        .init(code: "GR", name: "Grecia"),
        .init(code: "GB", name: "Regno Unito"),
        .init(code: "US", name: "Stati Uniti"),
        .init(code: "DE", name: "Germania"),
        .init(code: "NL", name: "Paesi Bassi"),
        .init(code: "CH", name: "Svizzera"),
        .init(code: "AT", name: "Austria"),
        .init(code: "HR", name: "Croazia"),
        .init(code: "MT", name: "Malta"),
        .init(code: "AE", name: "Emirati Arabi Uniti"),
        .init(code: "JP", name: "Giappone"),
        .init(code: "TH", name: "Thailandia"),
        .init(code: "MX", name: "Messico"),
        .init(code: "BR", name: "Brasile"),
        .init(code: "EG", name: "Egitto"),
        .init(code: "MA", name: "Marocco")
    ]
}

struct Trip: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var city: String
    var countryName: String
    var countryCode: String
    var startDate: Date
    var endDate: Date
    var coverImage: Data?
    var notes: String = ""
    var bookings: [Booking] = []
    var tickets: [TravelTicket] = []
    var expenses: [Expense] = []
    var packing: [PackingEntry] = []
    var places: [SavedPlace] = []

    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var packedCount: Int {
        packing.filter(\.isPacked).count
    }

    var duration: Int {
        max(1, (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1)
    }
}

enum BookingType: String, Codable, CaseIterable, Identifiable {
    case flight = "Volo"
    case hotel = "Hotel"
    case train = "Treno"
    case bus = "Autobus"
    case ferry = "Traghetto"
    case activity = "Attività"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .flight: return "airplane"
        case .hotel: return "building.2.fill"
        case .train: return "tram.fill"
        case .bus: return "bus.fill"
        case .ferry: return "ferry.fill"
        case .activity: return "ticket.fill"
        }
    }
}

struct Booking: Identifiable, Codable, Hashable {
    var id = UUID()
    var type: BookingType
    var title: String
    var provider: String
    var startDate: Date
    var location: String
    var confirmationCode: String
    var reminderEnabled: Bool
}

enum TicketType: String, Codable, CaseIterable, Identifiable {
    case boardingPass = "Carta d’imbarco"
    case hotelVoucher = "Voucher hotel"
    case trainTicket = "Biglietto treno"
    case eventTicket = "Biglietto evento"
    case insurance = "Assicurazione"
    case identity = "Documento"
    case other = "Altro"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .boardingPass: return "airplane"
        case .hotelVoucher: return "building.2.fill"
        case .trainTicket: return "tram.fill"
        case .eventTicket: return "ticket.fill"
        case .insurance: return "cross.case.fill"
        case .identity: return "person.text.rectangle.fill"
        case .other: return "doc.fill"
        }
    }
}

struct TravelTicket: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var type: TicketType
    var referenceCode: String
    var imageData: Data?
    var fileData: Data?
    var fileName: String?
    var notes: String
}

struct Expense: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var category: String
    var amount: Double
    var date: Date
}

struct PackingEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var isPacked: Bool = false
}

struct SavedPlace: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var address: String
}

func flagEmoji(for countryCode: String) -> String {
    let upper = countryCode.uppercased()
    guard upper.count == 2 else { return "🌍" }
    let base: UInt32 = 127397
    let scalars = upper.unicodeScalars.compactMap { UnicodeScalar(base + $0.value) }
    return String(String.UnicodeScalarView(scalars))
}
