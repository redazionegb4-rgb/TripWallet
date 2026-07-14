import SwiftUI

struct ItemsView: View {
    @Binding var trip: Trip
    @State private var showAdd = false

    var body: some View {
        List {
            if trip.bookings.isEmpty {
                EmptyInfoCard(
                    icon: "calendar.badge.plus",
                    title: "Nessuna prenotazione",
                    subtitle: "Aggiungi un volo, hotel, treno o attività."
                )
                .listRowBackground(Color.clear)
            }

            ForEach(trip.bookings.sorted { $0.startDate < $1.startDate }) { booking in
                HStack(spacing: 14) {
                    Image(systemName: booking.type.symbol)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.primaryGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 13))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(booking.title)
                            .font(.headline)
                        Text(booking.startDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if !booking.confirmationCode.isEmpty {
                            Text("Codice: \(booking.confirmationCode)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.violet)
                        }
                    }
                }
            }
            .onDelete { offsets in
                let sorted = trip.bookings.sorted { $0.startDate < $1.startDate }
                let ids = offsets.map { sorted[$0].id }
                trip.bookings.removeAll { ids.contains($0.id) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Prenotazioni")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddBookingView(trip: $trip)
        }
    }
}

private struct AddBookingView: View {
    @Binding var trip: Trip
    @Environment(\.dismiss) private var dismiss

    @State private var type: BookingType = .flight
    @State private var title = ""
    @State private var provider = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var code = ""
    @State private var reminder = true

    var body: some View {
        NavigationStack {
            Form {
                Picker("Tipo", selection: $type) {
                    ForEach(BookingType.allCases) { option in
                        Label(option.rawValue, systemImage: option.symbol)
                            .tag(option)
                    }
                }

                TextField("Titolo", text: $title)
                TextField("Compagnia o struttura", text: $provider)
                DatePicker("Data e ora", selection: $date)
                TextField("Luogo o aeroporto", text: $location)
                TextField("Codice prenotazione", text: $code)
                Toggle("Avviso 2 ore prima", isOn: $reminder)
            }
            .navigationTitle("Nuova prenotazione")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        let booking = Booking(
                            type: type,
                            title: title.isEmpty ? type.rawValue : title,
                            provider: provider,
                            startDate: date,
                            location: location,
                            confirmationCode: code,
                            reminderEnabled: reminder
                        )
                        trip.bookings.append(booking)
                        NotificationManager.shared.schedule(
                            booking: booking,
                            tripTitle: trip.title
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
