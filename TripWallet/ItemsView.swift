import SwiftUI

struct ItemsView: View {
    @Binding var trip: Trip
    @State private var editingItem: TravelItem?
    @State private var showNewItem = false

    private var groupedItems: [Date: [TravelItem]] {
        Dictionary(grouping: trip.items.sorted { $0.date < $1.date }) {
            Calendar.current.startOfDay(for: $0.date)
        }
    }

    var body: some View {
        List {
            if trip.items.isEmpty {
                EmptyStateView(
                    title: "Itinerario vuoto",
                    icon: "calendar.badge.plus",
                    message: "Aggiungi voli, alloggi, trasporti e attività."
                )
            }

            ForEach(groupedItems.keys.sorted(), id: \.self) { day in
                Section(day.formatted(date: .complete, time: .omitted)) {
                    ForEach(groupedItems[day] ?? []) { item in
                        Button {
                            editingItem = item
                        } label: {
                            HStack {
                                Image(systemName: item.type.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 28)

                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .foregroundStyle(.primary)

                                    Text(item.date.formatted(date: .omitted, time: .shortened) + (item.location.isEmpty ? "" : " • " + item.location))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if item.notify {
                                    Image(systemName: "bell.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                delete(item)
                            } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Itinerario")
        .toolbar {
            Button {
                showNewItem = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showNewItem) {
            NavigationStack {
                ItemEditor { item in
                    add(item)
                }
            }
        }
        .sheet(item: $editingItem) { item in
            NavigationStack {
                ItemEditor(existing: item) { updatedItem in
                    update(updatedItem)
                }
            }
        }
    }

    private func add(_ item: TravelItem) {
        trip.items.append(item)
        NotificationManager.shared.schedule(for: item, tripTitle: trip.title)
    }

    private func update(_ item: TravelItem) {
        if let index = trip.items.firstIndex(where: { $0.id == item.id }) {
            trip.items[index] = item
        }
        NotificationManager.shared.cancel(item.id)
        NotificationManager.shared.schedule(for: item, tripTitle: trip.title)
    }

    private func delete(_ item: TravelItem) {
        trip.items.removeAll { $0.id == item.id }
        NotificationManager.shared.cancel(item.id)
    }
}

struct ItemEditor: View {
    @Environment(\.dismiss) private var dismiss

    var existing: TravelItem?
    var onSave: (TravelItem) -> Void

    @State private var type: TravelItemType = .flight
    @State private var title = ""
    @State private var subtitle = ""
    @State private var date = Date()
    @State private var location = ""
    @State private var code = ""
    @State private var notes = ""
    @State private var notify = false

    var body: some View {
        Form {
            Section("Tipo") {
                Picker("Tipo", selection: $type) {
                    ForEach(TravelItemType.allCases) { itemType in
                        Label(itemType.rawValue, systemImage: itemType.icon)
                            .tag(itemType)
                    }
                }
            }

            Section("Dettagli") {
                TextField("Titolo", text: $title)
                TextField("Informazioni", text: $subtitle)
                DatePicker("Data e ora", selection: $date)
                TextField("Luogo / Terminal", text: $location)
                TextField("Codice prenotazione", text: $code)
            }

            Section {
                Toggle("Promemoria 2 ore prima", isOn: $notify)
            }

            Section("Note") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle(existing == nil ? "Nuovo elemento" : "Modifica")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annulla") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Salva") {
                    var item = existing ?? TravelItem(type: type, title: title, date: date)
                    item.type = type
                    item.title = title
                    item.subtitle = subtitle
                    item.date = date
                    item.location = location
                    item.bookingCode = code
                    item.notes = notes
                    item.notify = notify
                    onSave(item)
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            guard let item = existing else { return }
            type = item.type
            title = item.title
            subtitle = item.subtitle
            date = item.date
            location = item.location
            code = item.bookingCode
            notes = item.notes
            notify = item.notify
        }
    }
}
