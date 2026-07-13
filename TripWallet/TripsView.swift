import SwiftUI

struct TripsView: View {
    @EnvironmentObject private var store: TravelStore
    @State private var showNewTrip = false

    var body: some View {
        List {
            if !store.upcomingTrips.isEmpty {
                Section("In programma e in corso") {
                    ForEach(store.upcomingTrips) { trip in
                        NavigationLink(value: trip.id) {
                            TripRow(trip: trip)
                        }
                    }
                    .onDelete { offsets in
                        store.delete(at: offsets, from: store.upcomingTrips)
                    }
                }
            }

            if !store.pastTrips.isEmpty {
                Section("Viaggi passati") {
                    ForEach(store.pastTrips) { trip in
                        NavigationLink(value: trip.id) {
                            TripRow(trip: trip)
                        }
                    }
                    .onDelete { offsets in
                        store.delete(at: offsets, from: store.pastTrips)
                    }
                }
            }

            if store.trips.isEmpty {
                EmptyStateView(
                    title: "Nessun viaggio",
                    icon: "airplane",
                    message: "Tocca + per iniziare."
                )
            }
        }
        .navigationTitle("I miei viaggi")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewTrip = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationDestination(for: UUID.self) { id in
            if let tripBinding = store.tripBinding(id) {
                TripDetailView(trip: tripBinding)
            } else {
                Text("Viaggio non disponibile")
            }
        }
        .sheet(isPresented: $showNewTrip) {
            NavigationStack {
                TripEditorView()
            }
        }
    }
}

struct TripRow: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 14) {
            Text(flag(trip.countryCode))
                .font(.system(size: 34))

            VStack(alignment: .leading, spacing: 3) {
                Text(trip.title)
                    .font(.headline)

                Text(trip.destination)
                    .foregroundStyle(.secondary)

                Text(
                    trip.startDate.formatted(date: .abbreviated, time: .omitted)
                    + " – "
                    + trip.endDate.formatted(date: .abbreviated, time: .omitted)
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

struct TripEditorView: View {
    @EnvironmentObject private var store: TravelStore
    @Environment(\.dismiss) private var dismiss

    var existing: Trip? = nil

    @State private var title = ""
    @State private var destination = ""
    @State private var country = "IT"
    @State private var start = Date()
    @State private var end = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var notes = ""

    var body: some View {
        Form {
            Section("Viaggio") {
                TextField("Titolo (es. Estate 2026)", text: $title)
                TextField("Destinazione", text: $destination)
                TextField("Codice paese (IT, ES, FR...)", text: $country)
                    .textInputAutocapitalization(.characters)
            }

            Section("Date") {
                DatePicker("Partenza", selection: $start, displayedComponents: .date)
                DatePicker("Ritorno", selection: $end, in: start..., displayedComponents: .date)
            }

            Section("Note") {
                TextEditor(text: $notes)
                    .frame(minHeight: 90)
            }
        }
        .navigationTitle(existing == nil ? "Nuovo viaggio" : "Modifica viaggio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annulla") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Salva") {
                    save()
                }
                .disabled(
                    title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
        .onAppear {
            guard let trip = existing else { return }
            title = trip.title
            destination = trip.destination
            country = trip.countryCode
            start = trip.startDate
            end = trip.endDate
            notes = trip.notes
        }
    }

    private func save() {
        if var trip = existing {
            trip.title = title
            trip.destination = destination
            trip.countryCode = country
            trip.startDate = start
            trip.endDate = end
            trip.notes = notes
            store.update(trip)
        } else {
            store.add(
                Trip(
                    title: title,
                    destination: destination,
                    countryCode: country,
                    startDate: start,
                    endDate: end,
                    notes: notes
                )
            )
        }

        dismiss()
    }
}
