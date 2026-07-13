import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @Binding var trip: Trip
    @State private var showAdd = false
    @State private var selectedDocument: TravelDocument?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if trip.documents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 58))
                            .foregroundStyle(AppPalette.purple)
                        Text("Biglietti e QR")
                            .font(.title2.bold())
                        Text("Salva carte d’imbarco, voucher hotel, PDF e immagini con QR code.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(30)
                }

                ForEach(trip.documents) { document in
                    Button {
                        selectedDocument = document
                    } label: {
                        DocumentCard(document: document)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Biglietti e documenti")
        .toolbar {
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus.circle.fill")
            }
        }
        .sheet(isPresented: $showAdd) {
            AddDocumentView(trip: $trip)
        }
        .sheet(item: $selectedDocument) { document in
            DocumentPreview(document: document)
        }
    }
}

private struct DocumentCard: View {
    let document: TravelDocument

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                AppPalette.warmGradient
                Image(systemName: document.kind.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 17))

            VStack(alignment: .leading, spacing: 5) {
                Text(document.title)
                    .font(.headline)
                Text(document.kind.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !document.bookingCode.isEmpty {
                    Text("Codice: \(document.bookingCode)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.purple)
                }
            }

            Spacer()

            if document.imageData != nil {
                Image(systemName: "qrcode")
                    .foregroundStyle(AppPalette.purple)
            } else if document.fileData != nil {
                Image(systemName: "doc.richtext.fill")
                    .foregroundStyle(AppPalette.blue)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

private struct AddDocumentView: View {
    @Binding var trip: Trip
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var kind: DocumentKind = .flight
    @State private var bookingCode = ""
    @State private var notes = ""
    @State private var imageItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var fileName: String?
    @State private var fileData: Data?
    @State private var showFileImporter = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Dettagli") {
                    TextField("Titolo", text: $title)

                    Picker("Tipo", selection: $kind) {
                        ForEach(DocumentKind.allCases) { kind in
                            Label(kind.rawValue, systemImage: kind.icon)
                                .tag(kind)
                        }
                    }

                    TextField("Codice prenotazione", text: $bookingCode)
                    TextField("Note", text: $notes, axis: .vertical)
                }

                Section("Biglietto o QR code") {
                    PhotosPicker(selection: $imageItem, matching: .images) {
                        Label(
                            imageData == nil ? "Scegli foto o QR" : "Foto selezionata",
                            systemImage: "photo.on.rectangle"
                        )
                    }
                    .onChange(of: imageItem) { newValue in
                        Task {
                            imageData = try? await newValue?.loadTransferable(type: Data.self)
                        }
                    }

                    Button {
                        showFileImporter = true
                    } label: {
                        Label(
                            fileName == nil ? "Importa PDF o file" : fileName ?? "File selezionato",
                            systemImage: "doc.badge.plus"
                        )
                    }
                }

                if
                    let imageData,
                    let image = UIImage(data: imageData)
                {
                    Section("Anteprima") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 320)
                    }
                }
            }
            .navigationTitle("Nuovo biglietto")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        trip.documents.append(
                            TravelDocument(
                                title: title.isEmpty ? kind.rawValue : title,
                                kind: kind,
                                bookingCode: bookingCode,
                                imageData: imageData,
                                fileName: fileName,
                                fileData: fileData,
                                notes: notes
                            )
                        )
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                guard
                    case .success(let urls) = result,
                    let url = urls.first
                else { return }

                let access = url.startAccessingSecurityScopedResource()
                defer {
                    if access { url.stopAccessingSecurityScopedResource() }
                }

                fileName = url.lastPathComponent
                fileData = try? Data(contentsOf: url)
            }
        }
    }
}

private struct DocumentPreview: View {
    let document: TravelDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if
                        let data = document.imageData,
                        let image = UIImage(data: data)
                    {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        Image(systemName: document.kind.icon)
                            .font(.system(size: 80))
                            .foregroundStyle(AppPalette.purple)
                            .padding(40)
                    }

                    VStack(spacing: 8) {
                        Text(document.title)
                            .font(.title.bold())
                        Text(document.kind.rawValue)
                            .foregroundStyle(.secondary)
                        if !document.bookingCode.isEmpty {
                            Text(document.bookingCode)
                                .font(.title3.monospaced().bold())
                                .padding()
                                .background(AppPalette.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Anteprima")
            .toolbar {
                Button("Chiudi") { dismiss() }
            }
        }
    }
}

struct PlacesView: View {
    @Binding var trip: Trip
    @State private var name = ""
    @State private var address = ""

    var body: some View {
        List {
            Section("Nuovo luogo") {
                TextField("Nome", text: $name)
                TextField("Indirizzo", text: $address)
                Button("Aggiungi") {
                    guard !name.isEmpty else { return }
                    trip.places.append(
                        SavedPlace(
                            name: name,
                            address: address,
                            category: "Luogo"
                        )
                    )
                    name = ""
                    address = ""
                }
            }

            ForEach(trip.places) { place in
                VStack(alignment: .leading) {
                    Text(place.name)
                        .font(.headline)
                    Text(place.address)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete { trip.places.remove(atOffsets: $0) }
        }
        .navigationTitle("Luoghi salvati")
    }
}
