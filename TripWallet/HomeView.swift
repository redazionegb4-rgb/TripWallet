import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: TravelStore
    @State private var showNewTrip = false
    @State private var appeared = false

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
                        DestinationCard(trip: trip)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(appeared ? 1 : 0.96)
                    .opacity(appeared ? 1 : 0)

                    HStack {
                        Text("Partenza").font(.title2.bold())
                        Spacer()
                        Text(trip.daysUntilDeparture == 0 ? "Oggi" : "tra \(trip.daysUntilDeparture) giorni")
                            .font(.headline)
                            .foregroundStyle(AppTheme.violet)
                    }

                    Text("Riepilogo")
                        .font(.title2.bold())

                    HStack(spacing: 12) {
                        SummaryTile(
                            icon: "calendar",
                            value: "\(trip.duration)",
                            label: "giorni",
                            tint: AppTheme.violet
                        )
                        SummaryTile(
                            icon: "ticket.fill",
                            value: "\(trip.tickets.count)",
                            label: "biglietti",
                            tint: AppTheme.coral
                        )
                        SummaryTile(
                            icon: "suitcase.fill",
                            value: "\(trip.packedCount)/\(trip.packing.count)",
                            label: "valigia",
                            tint: AppTheme.blue
                        )
                    }

                    Text("Prossimi impegni")
                        .font(.title2.bold())

                    let futureBookings = trip.bookings
                        .filter { $0.startDate >= (Calendar.current.date(byAdding: .minute, value: -10, to: Date()) ?? Date()) }
                        .sorted { $0.startDate < $1.startDate }
                        .prefix(3)

                    if futureBookings.isEmpty {
                        EmptyInfoCard(
                            icon: "calendar.badge.plus",
                            title: "Nessun impegno",
                            subtitle: "Aggiungi voli, hotel o attività dal viaggio."
                        )
                    } else {
                        ForEach(Array(futureBookings)) { booking in
                            BookingRow(booking: booking)
                        }
                    }
                } else {
                    Button {
                        showNewTrip = true
                    } label: {
                        NewTripEmptyCard()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 30)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showNewTrip) {
            NewTripWizard()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Ciao, \(store.account.fullName.components(separatedBy: " ").first ?? store.account.fullName)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.violet)

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
                    .background(AppTheme.sunsetGradient)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.coral.opacity(0.28), radius: 12, y: 6)
                    .rotationEffect(.degrees(appeared ? 0 : -90))
            }
        }
    }
}

struct DestinationCard: View {
    let trip: Trip

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let data = trip.coverImage, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let value = trip.autoCoverURL, let url = URL(string: value) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image.resizable().scaledToFill()
                        } else {
                            AppTheme.primaryGradient
                        }
                    }
                } else {
                    AppTheme.primaryGradient
                }
            }
            .frame(height: 270)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.78)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 7) {
                Text(flagEmoji(for: trip.countryCode))
                    .font(.largeTitle)

                Text(trip.city)
                    .font(.system(size: 38, weight: .heavy, design: .rounded))

                Text(trip.countryName)
                    .font(.headline)

                Text("\(trip.startDate.formatted(date: .abbreviated, time: .omitted)) – \(trip.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.13), radius: 16, y: 9)
    }
}

private struct SummaryTile: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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

private struct BookingRow: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: booking.type.symbol)
                .font(.title3)
                .frame(width: 46, height: 46)
                .background(AppTheme.primaryGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.title)
                    .font(.headline)
                Text(booking.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct EmptyInfoCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppTheme.violet)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct NewTripEmptyCard: View {
    var body: some View {
        ZStack {
            AppTheme.primaryGradient

            VStack(spacing: 16) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 52))
                Text("Crea il tuo primo viaggio")
                    .font(.title2.bold())
                Text("Scegli destinazione, foto, date e poi aggiungi voli, hotel e biglietti.")
                    .multilineTextAlignment(.center)
                    .opacity(0.88)
            }
            .foregroundStyle(.white)
            .padding(26)
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}
