import SwiftUI

struct TripDetailView: View {
    @Binding var trip: Trip
    @State private var editTrip=false
    var body: some View { List { Section { VStack(alignment:.leading,spacing:10){HStack{Text(flag(trip.countryCode)).font(.system(size:44));VStack(alignment:.leading){Text(trip.destination).font(.title.bold());Text(trip.startDate.formatted(date:.long,time:.omitted)+" – "+trip.endDate.formatted(date:.long,time:.omitted)).foregroundStyle(.secondary)}};if !trip.notes.isEmpty{Text(trip.notes)}}.padding(.vertical,8) }
        Section("Organizza") {
            NavigationLink { ItemsView(trip:$trip) } label:{DetailLink(icon:"calendar.badge.clock",title:"Itinerario e prenotazioni",value:"\(trip.items.count)")}
            NavigationLink { ExpensesView(trip:$trip) } label:{DetailLink(icon:"eurosign.circle.fill",title:"Budget e spese",value:trip.totalSpent.formatted(.currency(code:"EUR")))}
            NavigationLink { PackingView(trip:$trip) } label:{DetailLink(icon:"suitcase.rolling.fill",title:"Valigia",value:"\(trip.packing.filter{$0.packed}.count)/\(trip.packing.count)")}
            NavigationLink { DocumentsView(trip:$trip) } label:{DetailLink(icon:"doc.fill",title:"Documenti e biglietti",value:"\(trip.documents.count)")}
            NavigationLink { PlacesView(trip:$trip) } label:{DetailLink(icon:"mappin.and.ellipse",title:"Luoghi salvati",value:"\(trip.places.count)")}
        }
    }.navigationTitle(trip.title).toolbar{Button("Modifica"){editTrip=true}}.sheet(isPresented:$editTrip){NavigationStack{TripEditorView(existing:trip)}} }
}
struct DetailLink:View{let icon,title,value:String;var body:some View{HStack{Image(systemName:icon).foregroundStyle(.blue).frame(width:30);Text(title);Spacer();Text(value).foregroundStyle(.secondary)}}}
