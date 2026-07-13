import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: TravelStore
    @State private var showNew = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Buon viaggio").font(.title.bold())
                        Text("Tutto ciò che ti serve, sempre con te").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { showNew = true } label: {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .padding(12)
                            .background(.blue.opacity(0.12))
                            .clipShape(Circle())
                    }
                }

                if let trip = store.upcomingTrips.first {
                    NavigationLink(value: trip.id) { HeroTripCard(trip: trip) }
                        .buttonStyle(.plain)
                } else {
                    EmptyHero { showNew = true }
                }

                if let trip = store.upcomingTrips.first {
                    Text("Prossimi eventi").font(.title2.bold())
                    let events = trip.items
                        .filter { $0.date >= Date() }
                        .sorted { $0.date < $1.date }
                        .prefix(3)

                    if events.isEmpty {
                        Text("Nessun evento programmato")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    ForEach(Array(events)) { EventRow(item: $0) }

                    HStack(spacing: 12) {
                        StatCard(icon: "calendar", value: "\(trip.daysCount)", label: "giorni")
                        StatCard(icon: "creditcard.fill", value: trip.totalSpent.formatted(.currency(code: "EUR")), label: "spesi")
                        StatCard(icon: "checkmark.circle.fill", value: "\(trip.packing.filter { $0.packed }.count)/\(trip.packing.count)", label: "valigia")
                    }
                }
            }
            .padding()
        }
        .navigationDestination(for: UUID.self) { id in
            if let binding = store.tripBinding(id) { TripDetailView(trip: binding) }
        }
        .sheet(isPresented: $showNew) { NavigationStack { TripEditorView() } }
        .navigationTitle("TripWallet")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HeroTripCard: View {
    let trip: Trip
    var days: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: trip.startDate)).day ?? 0
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [.indigo, .blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(flag(trip.countryCode)).font(.system(size: 34))
                    Spacer()
                    Image(systemName: "airplane").font(.title).rotationEffect(.degrees(-20))
                }
                Spacer()
                Text(trip.destination).font(.largeTitle.bold())
                Text(trip.startDate.formatted(date: .abbreviated, time: .omitted) + " – " + trip.endDate.formatted(date: .abbreviated, time: .omitted))
                Text(days > 0 ? "Partenza tra \(days) giorni" : days == 0 ? "Si parte oggi" : "Viaggio in corso")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
            }
            .foregroundStyle(.white)
            .padding()
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(radius: 10, y: 5)
    }
}

func flag(_ code: String) -> String {
    code.uppercased().unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }.map(String.init).joined()
}

struct EmptyHero: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Image(systemName: "airplane.circle.fill").font(.system(size: 60))
                Text("Crea il tuo primo viaggio").font(.title2.bold())
                Text("Aggiungi voli, hotel, documenti, spese e itinerario.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(34)
            .background(.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .buttonStyle(.plain)
    }
}

struct EventRow: View {
    let item: TravelItem
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.type.icon)
                .frame(width: 42, height: 42)
                .background(.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading) {
                Text(item.title).font(.headline)
                Text(item.date.formatted(date: .abbreviated, time: .shortened)).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(.blue)
            Text(value).font(.headline).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
