import SwiftUI

struct ExpensesView: View {
    @Binding var trip: Trip
    @State private var showNewExpense = false
    @State private var editingExpense: Expense?

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Totale speso")
                    Spacer()
                    Text(trip.totalSpent.formatted(.currency(code: "EUR")))
                        .font(.title3.bold())
                }
            }

            ForEach(trip.expenses.sorted { $0.date > $1.date }) { expense in
                Button {
                    editingExpense = expense
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.title)
                                .foregroundStyle(.primary)
                            Text(expense.category + " • " + expense.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(expense.amount.formatted(.currency(code: "EUR")))
                            .foregroundStyle(.primary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        trip.expenses.removeAll { $0.id == expense.id }
                    } label: {
                        Label("Elimina", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Spese")
        .toolbar {
            Button {
                showNewExpense = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showNewExpense) {
            NavigationStack {
                ExpenseEditor { newExpense in
                    trip.expenses.append(newExpense)
                }
            }
        }
        .sheet(item: $editingExpense) { expense in
            NavigationStack {
                ExpenseEditor(existing: expense) { updatedExpense in
                    if let index = trip.expenses.firstIndex(where: { $0.id == updatedExpense.id }) {
                        trip.expenses[index] = updatedExpense
                    }
                }
            }
        }
    }
}

struct ExpenseEditor: View {
    @Environment(\.dismiss) private var dismiss

    var existing: Expense?
    var save: (Expense) -> Void

    @State private var title = ""
    @State private var amount = 0.0
    @State private var category = "Altro"
    @State private var date = Date()
    @State private var notes = ""

    private let categories = ["Trasporti", "Alloggio", "Cibo", "Attività", "Shopping", "Altro"]

    var body: some View {
        Form {
            TextField("Descrizione", text: $title)
            TextField("Importo", value: $amount, format: .number)
                .keyboardType(.decimalPad)

            Picker("Categoria", selection: $category) {
                ForEach(categories, id: \.self) { item in
                    Text(item)
                }
            }

            DatePicker("Data", selection: $date, displayedComponents: .date)
            TextEditor(text: $notes)
                .frame(minHeight: 70)
        }
        .navigationTitle(existing == nil ? "Nuova spesa" : "Modifica spesa")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annulla") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Salva") {
                    var expense = existing ?? Expense(title: title, amount: amount, category: category, date: date)
                    expense.title = title
                    expense.amount = amount
                    expense.category = category
                    expense.date = date
                    expense.notes = notes
                    save(expense)
                    dismiss()
                }
                .disabled(title.isEmpty || amount <= 0)
            }
        }
        .onAppear {
            guard let expense = existing else { return }
            title = expense.title
            amount = expense.amount
            category = expense.category
            date = expense.date
            notes = expense.notes
        }
    }
}

struct PackingView: View {
    @Binding var trip: Trip
    @State private var text = ""
    @State private var category = "Altro"

    private let categories = ["Documenti", "Vestiti", "Igiene", "Tecnologia", "Medicinali", "Altro"]

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Nuovo elemento", text: $text)

                    Menu {
                        ForEach(categories, id: \.self) { item in
                            Button(item) {
                                category = item
                            }
                        }
                    } label: {
                        Text(category)
                    }

                    Button {
                        addItem()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            ForEach(categories, id: \.self) { currentCategory in
                let items = trip.packing.filter { $0.category == currentCategory }
                if !items.isEmpty {
                    Section(currentCategory) {
                        ForEach(items) { item in
                            Button {
                                toggle(item)
                            } label: {
                                HStack {
                                    Image(systemName: item.packed ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.packed ? .green : .secondary)
                                    Text(item.title)
                                        .strikethrough(item.packed)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    trip.packing.removeAll { $0.id == item.id }
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Valigia")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Predefiniti") {
                    addDefaults()
                }
            }
        }
    }

    private func addItem() {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }
        trip.packing.append(PackingItem(title: cleanText, category: category))
        text = ""
    }

    private func toggle(_ item: PackingItem) {
        if let index = trip.packing.firstIndex(where: { $0.id == item.id }) {
            trip.packing[index].packed.toggle()
        }
    }

    private func addDefaults() {
        let defaults = [
            ("Carta d’identità", "Documenti"),
            ("Biglietti", "Documenti"),
            ("Caricabatterie", "Tecnologia"),
            ("Spazzolino", "Igiene"),
            ("Intimo", "Vestiti"),
            ("Farmaci personali", "Medicinali")
        ]

        for (title, itemCategory) in defaults where !trip.packing.contains(where: { $0.title == title }) {
            trip.packing.append(PackingItem(title: title, category: itemCategory))
        }
    }
}
