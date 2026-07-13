import SwiftUI

struct ItemsView: View {
    @Binding var trip: Trip
    @State private var showAdd = false

    var body: some View {
        List {
            if trip.items.isEmpty {
                ModernEmptyRow(
                    icon: "calendar.badge.plus",
                    text: "Aggiungi volo, hotel o attività"
                )
                .listRowBackground(Color.clear)
            }

            ForEach(trip.items.sorted { $0.date < $1.date }) { item in
                HStack(spacing: 14) {
                    Image(systemName: item.type.icon)
                        .frame(width: 42, height: 42)
                        .background(AppPalette.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 13))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if !item.bookingCode.isEmpty {
                            Text("Codice: \(item.bookingCode)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppPalette.purple)
                        }
                    }
                }
            }
            .onDelete { offsets in
                let sorted = trip.items.sorted { $0.date < $1.date }
                let ids = offsets.map { sorted[$0].id }
                trip.items.removeAll { ids.contains($0.id) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Itinerario")
        .toolbar {
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddItemView(trip: $trip)
        }
    }
}

private struct AddItemView: View {
    @Binding var trip: Trip
    @Environment(\.dismiss) private var dismiss

    @State private var type: TravelItemType = .flight
    @State private var title = ""
    @State private var subtitle = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var bookingCode = ""
    @State private var notify = true

    var body: some View {
        NavigationStack {
            Form {
                Picker("Tipo", selection: $type) {
                    ForEach(TravelItemType.allCases) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }

                TextField("Titolo", text: $title)
                TextField("Compagnia o struttura", text: $subtitle)
                DatePicker("Data e ora", selection: $date)
                TextField("Luogo / aeroporto", text: $location)
                TextField("Codice prenotazione", text: $bookingCode)
                Toggle("Ricordami 2 ore prima", isOn: $notify)
            }
            .navigationTitle("Aggiungi")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        let item = TravelItem(
                            type: type,
                            title: title.isEmpty ? type.rawValue : title,
                            subtitle: subtitle,
                            date: date,
                            location: location,
                            bookingCode: bookingCode,
                            notify: notify
                        )
                        trip.items.append(item)
                        NotificationManager.shared.schedule(
                            for: item,
                            tripTitle: trip.title
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}
