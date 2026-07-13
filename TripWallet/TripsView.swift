import SwiftUI
import PhotosUI

struct TripsView: View {
    @EnvironmentObject private var store: TravelStore
    @State private var showNewTrip = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if store.trips.isEmpty {
                    ModernEmptyRow(
                        icon: "airplane.departure",
                        text: "Non hai ancora creato viaggi"
                    )
                } else {
                    ForEach(store.upcomingTrips) { trip in
                        NavigationLink {
                            TripDetailView(tripID: trip.id)
                        } label: {
                            TripListCard(trip: trip)
                        }
                        .buttonStyle(.plain)
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
                        .foregroundStyle(AppPalette.purple)
                }
            }
        }
        .sheet(isPresented: $showNewTrip) {
            NewTripWizard()
        }
    }
}

private struct TripListCard: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 15) {
            Group {
                if
                    let data = trip.coverImageData,
                    let image = UIImage(data: data)
                {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    AppPalette.gradient
                }
            }
            .frame(width: 92, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 22))

            VStack(alignment: .leading, spacing: 6) {
                Text("\(flagEmoji(countryCode: trip.countryCode)) \(trip.city)")
                    .font(.title3.bold())
                Text(trip.country)
                    .foregroundStyle(.secondary)
                Text(trip.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.purple)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 6)
    }
}

struct NewTripWizard: View {
    @EnvironmentObject private var store: TravelStore
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var title = ""
    @State private var city = ""
    @State private var country = ""
    @State private var countryCode = "IT"
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()
    @State private var notes = ""
    @State private var coverItem: PhotosPickerItem?
    @State private var coverData: Data?
    @State private var createdTripID: UUID?

    private var canGoNext: Bool {
        switch step {
        case 0:
            return !city.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !country.trimmingCharacters(in: .whitespaces).isEmpty
        default:
            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progress

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        if step == 0 {
                            destinationStep
                        } else if step == 1 {
                            coverStep
                        } else {
                            completedStep
                        }
                    }
                    .padding(22)
                }

                footer
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(step == 0 ? "Nuovo viaggio" : step == 1 ? "Copertina" : "Organizza")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }

    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? AppPalette.purple : Color.secondary.opacity(0.2))
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

            Group {
                TextField("Nome del viaggio, es. Estate 2026", text: $title)
                TextField("Città, es. Tenerife", text: $city)
                TextField("Paese, es. Spagna", text: $country)
                TextField("Codice paese, es. ES", text: $countryCode)
                    .textInputAutocapitalization(.characters)
            }
            .padding(16)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 17))

            DatePicker("Partenza", selection: $startDate, displayedComponents: .date)
            DatePicker("Ritorno", selection: $endDate, in: startDate..., displayedComponents: .date)

            TextField("Note facoltative", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding(16)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 17))
        }
    }

    private var coverStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Rendi unico il viaggio")
                .font(.system(size: 30, weight: .heavy, design: .rounded))

            Text("Scegli una foto della città: sarà visibile nella Home e nella scheda viaggio.")
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $coverItem, matching: .images) {
                ZStack {
                    if
                        let coverData,
                        let image = UIImage(data: coverData)
                    {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        AppPalette.warmGradient
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 44))
                            Text("Scegli foto copertina")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                    }
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .onChange(of: coverItem) { newValue in
                Task {
                    coverData = try? await newValue?.loadTransferable(type: Data.self)
                }
            }
        }
    }

    private var completedStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            ZStack {
                AppPalette.gradient
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 58))
                    Text("Viaggio creato")
                        .font(.title.bold())
                    Text("Ora inserisci voli, hotel, QR, documenti e tutto ciò che serve.")
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .padding(30)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))

            if let createdTripID {
                NavigationLink {
                    TripDetailView(tripID: createdTripID)
                } label: {
                    Label("Completa il viaggio", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(AppPalette.warmGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 19))
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step > 0 && step < 2 {
                Button("Indietro") {
                    step -= 1
                }
                .buttonStyle(.bordered)
            }

            Button {
                if step == 0 {
                    step = 1
                } else if step == 1 {
                    let trip = Trip(
                        title: title.isEmpty ? "\(city) \(Calendar.current.component(.year, from: startDate))" : title,
                        city: city,
                        country: country,
                        countryCode: countryCode,
                        startDate: startDate,
                        endDate: endDate,
                        notes: notes,
                        coverImageData: coverData
                    )
                    store.add(trip)
                    createdTripID = trip.id
                    step = 2
                } else {
                    dismiss()
                }
            } label: {
                Text(step == 0 ? "Continua" : step == 1 ? "Crea viaggio" : "Fine")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canGoNext ? AnyShapeStyle(AppPalette.gradient) : AnyShapeStyle(Color.gray.opacity(0.3)))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .disabled(!canGoNext)
        }
        .padding(18)
        .background(.ultraThinMaterial)
    }
}
