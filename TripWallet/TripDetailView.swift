import SwiftUI

struct TripDetailView: View {
    @EnvironmentObject private var store: TravelStore
    let tripID: UUID

    var body: some View {
        if let binding = store.binding(for: tripID) {
            TripDetailContent(trip: binding)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "airplane")
                    .font(.system(size: 54))
                    .foregroundStyle(AppPalette.purple)

                Text("Viaggio non trovato")
                    .font(.title2.bold())

                Text("Il viaggio potrebbe essere stato eliminato o non è più disponibile.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

private struct TripDetailContent: View {
    @Binding var trip: Trip

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                HeroTripCardDetail(trip: trip)

                LazyVGrid(columns: columns, spacing: 14) {
                    NavigationLink {
                        ItemsView(trip: $trip)
                    } label: {
                        FeatureCard(
                            title: "Itinerario",
                            subtitle: "\(trip.items.count) elementi",
                            icon: "calendar.badge.clock",
                            colors: [AppPalette.purple, AppPalette.blue]
                        )
                    }

                    NavigationLink {
                        DocumentsView(trip: $trip)
                    } label: {
                        FeatureCard(
                            title: "Biglietti",
                            subtitle: "\(trip.documents.count) salvati",
                            icon: "qrcode.viewfinder",
                            colors: [AppPalette.pink, AppPalette.orange]
                        )
                    }

                    NavigationLink {
                        ExpensesView(trip: $trip)
                    } label: {
                        FeatureCard(
                            title: "Spese",
                            subtitle: trip.totalSpent.formatted(.currency(code: "EUR")),
                            icon: "creditcard.fill",
                            colors: [AppPalette.blue, AppPalette.cyan]
                        )
                    }

                    NavigationLink {
                        PackingView(trip: $trip)
                    } label: {
                        FeatureCard(
                            title: "Valigia",
                            subtitle: "\(trip.packing.filter(\.packed).count)/\(trip.packing.count)",
                            icon: "suitcase.rolling.fill",
                            colors: [AppPalette.orange, AppPalette.pink]
                        )
                    }

                    NavigationLink {
                        PlacesView(trip: $trip)
                    } label: {
                        FeatureCard(
                            title: "Luoghi",
                            subtitle: "\(trip.places.count) salvati",
                            icon: "map.fill",
                            colors: [AppPalette.cyan, AppPalette.blue]
                        )
                    }
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct HeroTripCardDetail: View {
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
            .frame(height: 245)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("\(flagEmoji(countryCode: trip.countryCode)) \(trip.city)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                Text(trip.country)
                    .font(.headline)
                Text("\(trip.startDate.formatted(date: .long, time: .omitted)) – \(trip.endDate.formatted(date: .long, time: .omitted))")
                    .font(.subheadline)
            }
            .foregroundStyle(.white)
            .padding(22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

private struct FeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 15))

            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .opacity(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
