import SwiftUI

struct TripDetailView: View {
    @EnvironmentObject private var store: TravelStore
    let tripID: UUID

    var body: some View {
        if let trip = store.binding(for: tripID) {
            TripDetailContent(trip: trip)
        } else {
            VStack(spacing: 14) {
                Image(systemName: "airplane")
                    .font(.system(size: 54))
                    .foregroundStyle(AppTheme.violet)
                Text("Viaggio non trovato")
                    .font(.title2.bold())
            }
        }
    }
}

private struct TripDetailContent: View {
    @Binding var trip: Trip

    private let columns = [
        GridItem(.flexible(), spacing: 13),
        GridItem(.flexible(), spacing: 13)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                DestinationCard(trip: trip)

                LazyVGrid(columns: columns, spacing: 13) {
                    NavigationLink {
                        ItemsView(trip: $trip)
                    } label: {
                        FeatureTile(
                            title: "Prenotazioni",
                            subtitle: "\(trip.bookings.count)",
                            icon: "calendar.badge.clock",
                            gradient: AppTheme.primaryGradient
                        )
                    }

                    NavigationLink {
                        DocumentsView(trip: $trip)
                    } label: {
                        FeatureTile(
                            title: "Biglietti e QR",
                            subtitle: "\(trip.tickets.count)",
                            icon: "qrcode.viewfinder",
                            gradient: AppTheme.sunsetGradient
                        )
                    }

                    NavigationLink {
                        ExpensesView(trip: $trip)
                    } label: {
                        FeatureTile(
                            title: "Spese",
                            subtitle: trip.totalExpenses.formatted(.currency(code: "EUR")),
                            icon: "creditcard.fill",
                            gradient: LinearGradient(
                                colors: [AppTheme.blue, AppTheme.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }

                    NavigationLink {
                        PackingView(trip: $trip)
                    } label: {
                        FeatureTile(
                            title: "Valigia",
                            subtitle: "\(trip.packedCount)/\(trip.packing.count)",
                            icon: "suitcase.rolling.fill",
                            gradient: LinearGradient(
                                colors: [AppTheme.coral, AppTheme.yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }

                    NavigationLink {
                        PlacesView(trip: $trip)
                    } label: {
                        FeatureTile(
                            title: "Luoghi",
                            subtitle: "\(trip.places.count)",
                            icon: "map.fill",
                            gradient: LinearGradient(
                                colors: [AppTheme.cyan, AppTheme.violet],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(trip.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FeatureTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline.weight(.semibold))
                .opacity(0.88)
        }
        .frame(maxWidth: .infinity, minHeight: 135, alignment: .leading)
        .padding(17)
        .background(gradient)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 23))
    }
}
