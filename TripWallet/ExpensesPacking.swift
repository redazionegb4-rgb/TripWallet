import SwiftUI

struct ExpensesView: View {
    @Binding var trip: Trip
    @State private var showAdd = false

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Totale speso")
                        .font(.headline)
                    Spacer()
                    Text(trip.totalExpenses.formatted(.currency(code: "EUR")))
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.violet)
                }
            }

            ForEach(trip.expenses) { expense in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(expense.title)
                            .font(.headline)
                        Text(expense.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(expense.amount.formatted(.currency(code: "EUR")))
                        .fontWeight(.semibold)
                }
            }
            .onDelete { trip.expenses.remove(atOffsets: $0) }
        }
        .navigationTitle("Spese")
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
            AddExpenseView(trip: $trip)
        }
    }
}

private struct AddExpenseView: View {
    @Binding var trip: Trip
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amount = 0.0
    @State private var category = "Altro"

    var body: some View {
        NavigationStack {
            Form {
                TextField("Descrizione", text: $title)
                TextField("Importo", value: $amount, format: .number)
                    .keyboardType(.decimalPad)

                Picker("Categoria", selection: $category) {
                    ForEach(
                        ["Voli", "Hotel", "Cibo", "Trasporti", "Attività", "Shopping", "Altro"],
                        id: \.self
                    ) {
                        Text($0)
                    }
                }
            }
            .navigationTitle("Nuova spesa")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        trip.expenses.append(
                            Expense(
                                title: title.isEmpty ? category : title,
                                category: category,
                                amount: amount,
                                date: Date()
                            )
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PackingView: View {
    @Binding var trip: Trip
    @State private var newItem = ""

    var body: some View {
        List {
            HStack {
                TextField("Nuovo elemento", text: $newItem)
                Button {
                    let clean = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !clean.isEmpty else { return }
                    trip.packing.append(PackingEntry(title: clean))
                    newItem = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }

            ForEach($trip.packing) { $item in
                Button {
                    item.isPacked.toggle()
                } label: {
                    HStack {
                        Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isPacked ? AppTheme.violet : .secondary)
                        Text(item.title)
                            .foregroundStyle(.primary)
                            .strikethrough(item.isPacked)
                    }
                }
            }
            .onDelete { trip.packing.remove(atOffsets: $0) }
        }
        .navigationTitle("Valigia")
    }
}
