import SwiftUI

struct ExpensesView: View {
    @Binding var trip: Trip
    @State private var showAdd = false

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Totale")
                        .font(.headline)
                    Spacer()
                    Text(trip.totalSpent.formatted(.currency(code: "EUR")))
                        .font(.title2.bold())
                        .foregroundStyle(AppPalette.purple)
                }
            }

            ForEach(trip.expenses) { expense in
                HStack {
                    VStack(alignment: .leading) {
                        Text(expense.title)
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
        .navigationTitle("Budget e spese")
        .toolbar {
            Button {
                showAdd = true
            } label: {
                Image(systemName: "plus.circle.fill")
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
                    ForEach(["Voli", "Hotel", "Cibo", "Trasporti", "Attività", "Shopping", "Altro"], id: \.self) {
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
                                amount: amount,
                                category: category,
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
                TextField("Aggiungi alla valigia", text: $newItem)
                Button {
                    guard !newItem.isEmpty else { return }
                    trip.packing.append(
                        PackingItem(title: newItem, category: "Personale")
                    )
                    newItem = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }

            ForEach($trip.packing) { $item in
                Button {
                    item.packed.toggle()
                } label: {
                    HStack {
                        Image(systemName: item.packed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.packed ? AppPalette.purple : .secondary)
                        Text(item.title)
                            .strikethrough(item.packed)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .onDelete { trip.packing.remove(atOffsets: $0) }
        }
        .navigationTitle("Valigia")
    }
}
