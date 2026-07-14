import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct DocumentsView: View {
    @Binding var trip: Trip
    @State private var showAdd = false
    @State private var previewTicket: TravelTicket?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if trip.tickets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 58))
                            .foregroundStyle(AppTheme.violet)
                        Text("Biglietti e QR code")
                            .font(.title2.bold())
                        Text("Salva carte d’imbarco, voucher hotel, immagini e PDF.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(30)
                }

                ForEach(trip.tickets) { ticket in
                    Button {
                        previewTicket = ticket
                    } label: {
                        TicketCard(ticket: ticket)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Biglietti e QR")
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
            AddTicketView(trip: $trip)
        }
        .sheet(item: $previewTicket) { ticket in
            TicketPreview(ticket: ticket)
        }
    }
}

private struct TicketCard: View {
    let ticket: TravelTicket

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                AppTheme.sunsetGradient
                Image(systemName: ticket.type.symbol)
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .frame(width: 58, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 17))

            VStack(alignment: .leading, spacing: 5) {
                Text(ticket.title)
                    .font(.headline)
                Text(ticket.type.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !ticket.referenceCode.isEmpty {
                    Text("Codice: \(ticket.referenceCode)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.violet)
                }
            }

            Spacer()

            Image(systemName: ticket.imageData != nil ? "qrcode" : "doc.fill")
                .foregroundStyle(AppTheme.violet)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

private struct AddTicketView: View {
    @Binding var trip: Trip
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var type: TicketType = .boardingPass
    @State private var referenceCode = ""
    @State private var notes = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var fileData: Data?
    @State private var fileName: String?
    @State private var showImporter = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Informazioni") {
                    TextField("Titolo", text: $title)

                    Picker("Tipo", selection: $type) {
                        ForEach(TicketType.allCases) { option in
                            Label(option.rawValue, systemImage: option.symbol)
                                .tag(option)
                        }
                    }

                    TextField("Codice prenotazione", text: $referenceCode)
                    TextField("Note", text: $notes, axis: .vertical)
                }

                Section("Allegato") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(
                            imageData == nil ? "Scegli foto o QR code" : "Foto selezionata",
                            systemImage: "photo.on.rectangle"
                        )
                    }
                    .onChange(of: photoItem) { item in
                        Task {
                            imageData = try? await item?.loadTransferable(type: Data.self)
                        }
                    }

                    Button {
                        showImporter = true
                    } label: {
                        Label(
                            fileName ?? "Importa PDF",
                            systemImage: "doc.badge.plus"
                        )
                    }
                }

                if let imageData, let image = UIImage(data: imageData) {
                    Section("Anteprima") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
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
                        trip.tickets.append(
                            TravelTicket(
                                title: title.isEmpty ? type.rawValue : title,
                                type: type,
                                referenceCode: referenceCode,
                                imageData: imageData,
                                fileData: fileData,
                                fileName: fileName,
                                notes: notes
                            )
                        )
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { result in
                guard
                    case .success(let urls) = result,
                    let url = urls.first
                else { return }

                let hasAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if hasAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                fileName = url.lastPathComponent
                fileData = try? Data(contentsOf: url)
            }
        }
    }
}

private struct TicketPreview: View {
    let ticket: TravelTicket
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let data = ticket.imageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        ZStack {
                            AppTheme.primaryGradient
                            Image(systemName: ticket.type.symbol)
                                .font(.system(size: 70))
                                .foregroundStyle(.white)
                        }
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }

                    Text(ticket.title)
                        .font(.title.bold())

                    Text(ticket.type.rawValue)
                        .foregroundStyle(.secondary)

                    if !ticket.referenceCode.isEmpty {
                        Text(ticket.referenceCode)
                            .font(.title3.monospaced().bold())
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.violet.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Anteprima")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Chiudi") { dismiss() }
                }
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

                Button("Aggiungi luogo") {
                    let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !clean.isEmpty else { return }

                    trip.places.append(
                        SavedPlace(name: clean, address: address)
                    )
                    name = ""
                    address = ""
                }
            }

            ForEach(trip.places) { place in
                VStack(alignment: .leading, spacing: 4) {
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
