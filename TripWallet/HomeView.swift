import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: TravelStore
    @State private var showNewTrip = false

    private var nextTrip: Trip? {
        store.upcomingTrips.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if let trip = nextTrip {
                    NavigationLink {
                        TripDetailView(tripID: trip.id)
                    } label: {
                        HeroTripCard(trip: trip)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        showNewTrip = true
                    } label: {
                        EmptyHeroCard()
                    }
                    .buttonStyle(.plain)
                }

                if let trip = nextTrip {
                    Text("Il tuo viaggio")
                        .font(.title2.bold())

                    quickStats(trip)

                    Text("Prossimi appuntamenti")
                        .font(.title2.bold())

                    let futureItems = trip.items
                        .filter { $0.date >= Date() }
                        .sorted { $0.date < $1.date }
                        .prefix(3)

                    if futureItems.isEmpty {
                        ModernEmptyRow(
                            icon: "calendar.badge.plus",
                            text: "Aggiungi voli, hotel o attività"
                        )
                    } else {
                        ForEach(Array(futureItems)) { item in
                            HStack(spacing: 14) {
                                Image(systemName: item.type.icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(AppPalette.gradient)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.headline)
                                    Text(item.date.formatted(
                                        date: .abbreviated,
                                        time: .shortened
                                    ))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(.background)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.06), radius: 14, y: 7)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNewTrip) {
            NewTripWizard()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Ciao, \(store.profile.name)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.purple)

                Text("Dove si parte?")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
            }

            Spacer()

            Button {
                showNewTrip = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .frame(width: 54, height: 54)
                    .background(AppPalette.warmGradient)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .shadow(color: AppPalette.pink.opacity(0.3), radius: 12, y: 6)
            }
        }
        .padding(.top, 12)
    }

    private func quickStats(_ trip: Trip) -> some View {
        HStack(spacing: 12) {
            MiniStat(
                icon: "calendar",
                value: "\(trip.daysCount)",
                label: "giorni",
                color: AppPalette.purple
            )
            MiniStat(
                icon: "creditcard.fill",
                value: trip.totalSpent.formatted(.currency(code: "EUR")),
                label: "spesi",
                color: AppPalette.blue
            )
            MiniStat(
                icon: "ticket.fill",
                value: "\(trip.documents.count)",
                label: "biglietti",
                color: AppPalette.pink
            )
        }
    }
}

private struct HeroTripCard: View {
    let trip: Trip

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if
                    let data = trip.coverImageData,
                    let image = UIImage(data: data)
                {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    AppPalette.warmGradient
                }
            }
            .frame(height: 270)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(flagEmoji(countryCode: trip.countryCode))
                    .font(.largeTitle)

                Text(trip.city.isEmpty ? trip.country : trip.city)
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(trip.country)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.86))

                Text("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) – \(trip.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(color: AppPalette.purple.opacity(0.22), radius: 20, y: 10)
    }
}

private struct EmptyHeroCard: View {
    var body: some View {
        ZStack {
            AppPalette.gradient
            VStack(spacing: 16) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 54))
                    .foregroundStyle(.white)
                Text("Crea il tuo primo viaggio")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Aggiungi destinazione, copertina, voli, hotel e biglietti.")
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(28)
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

private struct MiniStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct ModernEmptyRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppPalette.purple)
            Text(text)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

func flagEmoji(countryCode: String) -> String {
    let code = countryCode.uppercased()
    guard code.count == 2 else { return "🌍" }
    let scalars = code.unicodeScalars.compactMap {
        UnicodeScalar(127397 + $0.value)
    }
    return String(String.UnicodeScalarView(scalars))
}
