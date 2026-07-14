import SwiftUI

struct ItemsView: View {
    @Binding var trip: Trip
    @State private var showAdd = false
    @State private var bookingToEdit: Booking?

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
                Button { bookingToEdit = booking } label: {
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
                .buttonStyle(.plain)
                .contextMenu {
                    Button { bookingToEdit = booking } label: { Label("Modifica", systemImage: "pencil") }
                    Button(role: .destructive) { trip.bookings.removeAll { $0.id == booking.id } } label: { Label("Elimina", systemImage: "trash") }
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
            BookingEditorView(trip: $trip, booking: nil)
        }
        .sheet(item: $bookingToEdit) { booking in
            BookingEditorView(trip: $trip, booking: booking)
        }
    }
}

private struct BookingEditorView: View {
    @Binding var trip: Trip
    @Environment(\.dismiss) private var dismiss

    let booking: Booking?
    @State private var type: BookingType
    @State private var title: String
    @State private var provider: String
    @State private var date: Date
    @State private var location: String
    @State private var code: String
    @State private var reminder: Bool

    init(trip: Binding<Trip>, booking: Booking?) {
        _trip = trip
        self.booking = booking
        _type = State(initialValue: booking?.type ?? .flight)
        _title = State(initialValue: booking?.title ?? "")
        _provider = State(initialValue: booking?.provider ?? "")
        _date = State(initialValue: booking?.startDate ?? Date())
        _location = State(initialValue: booking?.location ?? "")
        _code = State(initialValue: booking?.confirmationCode ?? "")
        _reminder = State(initialValue: booking?.reminderEnabled ?? true)
    }

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
            .navigationTitle(booking == nil ? "Nuova prenotazione" : "Modifica prenotazione")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        let booking = Booking(
                            id: booking?.id ?? UUID(),
                            type: type,
                            title: title.isEmpty ? type.rawValue : title,
                            provider: provider,
                            startDate: date,
                            location: location,
                            confirmationCode: code,
                            reminderEnabled: reminder
                        )
                        if let index = trip.bookings.firstIndex(where: { $0.id == booking.id }) {
                            trip.bookings[index] = booking
                        } else {
                            trip.bookings.append(booking)
                        }
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
