import SwiftUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @Binding var trip: Trip
    @State private var showEditor = false
    @State private var documentToImport: TravelDocument?

    var body: some View {
        List {
            if trip.documents.isEmpty {
                EmptyStateView(
                    title: "Nessun documento",
                    icon: "doc.badge.plus",
                    message: "Salva passaporti, assicurazioni, biglietti e PDF."
                )
            }

            ForEach(trip.documents) { document in
                HStack {
                    Image(systemName: document.fileName == nil ? "doc.text.fill" : "doc.richtext.fill")
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading) {
                        Text(document.title)
                        Text(documentSubtitle(document))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        documentToImport = document
                    } label: {
                        Image(systemName: "paperclip")
                    }
                    .buttonStyle(.borderless)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        trip.documents.removeAll { $0.id == document.id }
                    } label: {
                        Label("Elimina", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Documenti")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                DocumentEditor { newDocument in
                    trip.documents.append(newDocument)
                }
            }
        }
        .fileImporter(
            isPresented: Binding(
                get: { documentToImport != nil },
                set: { isPresented in
                    if !isPresented {
                        documentToImport = nil
                    }
                }
            ),
            allowedContentTypes: [.pdf, .image, .data]
        ) { result in
            handleImport(result)
        }
    }

    private func documentSubtitle(_ document: TravelDocument) -> String {
        guard let fileName = document.fileName else {
            return document.type
        }
        return "\(document.type) • \(fileName)"
    }

    private func handleImport(_ result: Result<URL, Error>) {
        defer { documentToImport = nil }

        guard
            case .success(let url) = result,
            let selectedDocument = documentToImport,
            let index = trip.documents.firstIndex(where: { $0.id == selectedDocument.id })
        else {
            return
        }

        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        trip.documents[index].fileName = url.lastPathComponent
        trip.documents[index].bookmarkData = try? url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
}

struct DocumentEditor: View {
    @Environment(\.dismiss) private var dismiss

    let save: (TravelDocument) -> Void

    @State private var title = ""
    @State private var type = "Biglietto"
    @State private var hasExpiry = false
    @State private var expiry = Date()
    @State private var notes = ""

    private let types = [
        "Passaporto",
        "Carta d’identità",
        "Biglietto",
        "Assicurazione",
        "Prenotazione",
        "Altro"
    ]

    var body: some View {
        Form {
            TextField("Titolo", text: $title)

            Picker("Tipo", selection: $type) {
                ForEach(types, id: \.self) { item in
                    Text(item)
                }
            }

            Toggle("Ha una scadenza", isOn: $hasExpiry)

            if hasExpiry {
                DatePicker(
                    "Scadenza",
                    selection: $expiry,
                    displayedComponents: .date
                )
            }

            TextEditor(text: $notes)
                .frame(minHeight: 80)
        }
        .navigationTitle("Nuovo documento")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annulla") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Salva") {
                    save(
                        TravelDocument(
                            title: title,
                            type: type,
                            expiryDate: hasExpiry ? expiry : nil,
                            notes: notes
                        )
                    )
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

struct PlacesView: View {
    @Binding var trip: Trip
    @State private var showEditor = false

    var body: some View {
        List {
            if trip.places.isEmpty {
                EmptyStateView(
                    title: "Nessun luogo",
                    icon: "mappin.slash",
                    message: "Salva ristoranti, spiagge, musei e altri posti."
                )
            }

            ForEach(trip.places) { place in
                VStack(alignment: .leading) {
                    Text(place.name)
                        .font(.headline)

                    Text(placeSubtitle(place))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !place.notes.isEmpty {
                        Text(place.notes)
                            .font(.subheadline)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        trip.places.removeAll { $0.id == place.id }
                    } label: {
                        Label("Elimina", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Luoghi")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                PlaceEditor { newPlace in
                    trip.places.append(newPlace)
                }
            }
        }
    }

    private func placeSubtitle(_ place: SavedPlace) -> String {
        guard !place.address.isEmpty else {
            return place.category
        }
        return "\(place.category) • \(place.address)"
    }
}

struct PlaceEditor: View {
    @Environment(\.dismiss) private var dismiss

    let save: (SavedPlace) -> Void

    @State private var name = ""
    @State private var address = ""
    @State private var category = "Da visitare"
    @State private var notes = ""

    private let categories = [
        "Da visitare",
        "Ristorante",
        "Spiaggia",
        "Museo",
        "Shopping",
        "Altro"
    ]

    var body: some View {
        Form {
            TextField("Nome", text: $name)
            TextField("Indirizzo", text: $address)

            Picker("Categoria", selection: $category) {
                ForEach(categories, id: \.self) { item in
                    Text(item)
                }
            }

            TextEditor(text: $notes)
                .frame(minHeight: 80)
        }
        .navigationTitle("Nuovo luogo")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annulla") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Salva") {
                    save(
                        SavedPlace(
                            name: name,
                            address: address,
                            category: category,
                            notes: notes
                        )
                    )
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
