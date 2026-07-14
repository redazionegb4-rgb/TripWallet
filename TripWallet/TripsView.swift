import SwiftUI
import PhotosUI

struct TripsView: View {
    @EnvironmentObject private var store: TravelStore
    @State private var showNewTrip = false
    @State private var tripToDelete: Trip?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                if store.trips.isEmpty {
                    EmptyInfoCard(
                        icon: "airplane.departure",
                        title: "Nessun viaggio",
                        subtitle: "Tocca + per creare il primo."
                    )
                } else {
                    ForEach(store.upcomingTrips) { trip in
                        NavigationLink {
                            TripDetailView(tripID: trip.id)
                        } label: {
                            TripListCard(trip: trip)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                tripToDelete = trip
                            } label: {
                                Label("Elimina viaggio", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("I miei viaggi")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewTrip = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AppTheme.violet)
                }
            }
        }
        .sheet(isPresented: $showNewTrip) {
            NewTripWizard()
        }
        .confirmationDialog("Eliminare questo viaggio?", isPresented: Binding(
            get: { tripToDelete != nil },
            set: { if !$0 { tripToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Elimina viaggio", role: .destructive) {
                if let tripToDelete { store.deleteTrip(tripToDelete) }
                tripToDelete = nil
            }
            Button("Annulla", role: .cancel) { tripToDelete = nil }
        }
    }
}

private struct TripListCard: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 15) {
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
            .frame(width: 94, height: 94)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 5) {
                Text("\(flagEmoji(for: trip.countryCode)) \(trip.city)")
                    .font(.title3.bold())
                Text(trip.countryName)
                    .foregroundStyle(.secondary)
                Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.violet)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct NewTripWizard: View {
    @EnvironmentObject private var store: TravelStore
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var title = ""
    @State private var city = ""
    @State private var selectedCountry = CountryOption.common[1]
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
    @State private var notes = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var coverData: Data?
    @State private var useAutomaticPhoto = true
    @State private var createdID: UUID?

    private var canContinue: Bool {
        step != 0 || !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        switch step {
                        case 0:
                            destinationStep
                        case 1:
                            coverStep
                        default:
                            completionStep
                        }
                    }
                    .padding(22)
                }
                .scrollDismissesKeyboard(.interactively)

                bottomBar
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(step == 0 ? "Destinazione" : step == 1 ? "Copertina" : "Pronto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? AppTheme.violet : Color.secondary.opacity(0.2))
                    .frame(height: 6)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
    }

    private var destinationStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Dove vuoi andare?")
                .font(.system(size: 30, weight: .heavy, design: .rounded))

            StyledTextField(title: "Nome viaggio, es. Estate 2026", text: $title)
            StyledTextField(title: "Città, es. Tenerife", text: $city)

            VStack(alignment: .leading, spacing: 8) {
                Text("Paese")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("Paese", selection: $selectedCountry) {
                    ForEach(CountryOption.common) { country in
                        Text("\(flagEmoji(for: country.code)) \(country.name)")
                            .tag(country)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 17))
            }

            DatePicker("Partenza", selection: $startDate, displayedComponents: .date)
                .padding(16)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 17))

            DatePicker("Ritorno", selection: $endDate, in: startDate..., displayedComponents: .date)
                .padding(16)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 17))

            TextField("Note facoltative", text: $notes, axis: .vertical)
                .lineLimit(3...5)
                .padding(16)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 17))
        }
    }

    private var coverStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Copertina del viaggio")
                .font(.system(size: 30, weight: .heavy, design: .rounded))

            Toggle("Usa automaticamente una foto della destinazione", isOn: $useAutomaticPhoto)
                .padding(16)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 17))

            Text("La città sarà sempre visibile sopra la foto, insieme al Paese e alle date.")
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomLeading) {
                    Group {
                        if let coverData, let image = UIImage(data: coverData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            AppTheme.sunsetGradient
                        }
                    }
                    .frame(height: 270)
                    .clipped()

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(flagEmoji(for: selectedCountry.code)) \(city)")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                        Text(selectedCountry.name)
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .padding(20)
                }
                .clipShape(RoundedRectangle(cornerRadius: 26))
            }
            .onChange(of: photoItem) { item in
                Task {
                    coverData = try? await item?.loadTransferable(type: Data.self)
                }
            }

            Text("Tocca la copertina per scegliere una foto dalla libreria.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var completionStep: some View {
        VStack(spacing: 20) {
            ZStack {
                AppTheme.primaryGradient
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 58))
                    Text("Viaggio creato")
                        .font(.title.bold())
                    Text("Adesso completa voli, hotel, biglietti, QR code, valigia e luoghi.")
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .padding(28)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26))

            if let createdID {
                NavigationLink {
                    TripDetailView(tripID: createdID)
                } label: {
                    Label("Completa il viaggio", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.sunsetGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if step == 1 {
                Button("Indietro") { step = 0 }
                    .buttonStyle(.bordered)
            }

            Button {
                if step == 0 {
                    step = 1
                } else if step == 1 {
                    let trip = Trip(
                        title: title.isEmpty ? "\(city) \(Calendar.current.component(.year, from: startDate))" : title,
                        city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                        countryName: selectedCountry.name,
                        countryCode: selectedCountry.code,
                        startDate: startDate,
                        endDate: endDate,
                        coverImage: coverData,
                        autoCoverURL: useAutomaticPhoto && coverData == nil ? automaticDestinationPhotoURL(city: city, country: selectedCountry.name) : nil,
                        notes: notes
                    )
                    store.addTrip(trip)
                    createdID = trip.id
                    step = 2
                } else {
                    dismiss()
                }
            } label: {
                Text(step == 0 ? "Continua" : step == 1 ? "Crea viaggio" : "Fine")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canContinue ? AnyShapeStyle(AppTheme.primaryGradient) : AnyShapeStyle(Color.gray.opacity(0.3)))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .disabled(!canContinue)
        }
        .padding(18)
        .background(.ultraThinMaterial)
    }
}

private struct StyledTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        TextField(title, text: $text)
            .padding(16)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 17))
    }
}
