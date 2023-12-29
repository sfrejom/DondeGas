import SwiftUI
import MapKit
import CoreLocation

@main
struct DondeGasApp: App {
    @StateObject var viewModel = DondeGasViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .accentColor(Color("TextColor"))
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @StateObject var locationManager = LocationManager.shared
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            GasStationsMap()
            
            VStack {
                Spacer()
                
                // Filters
                ZStack {
                    FuelMenuCardView()
                    LocationMenuCardView()
                }
                
                // Filters menu
                FilterButtons()
                
                // Tarjeta deslizante
                SlidingCardView()
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            viewModel.loadGasStations()
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct GasStationsMap: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @StateObject var locationManager = LocationManager.shared
    
    var body: some View {
        Map {
            ForEach(viewModel.gasStationLocations, id: \.id) { station in
                Annotation( "", coordinate: station.location, anchor: .center, content: {
                    Button(action: {
                        viewModel.expandedItem = station.id
                    }) {
                        Image(systemName: "fuelpump.circle.fill")
                            .foregroundColor(viewModel.getColorCode(gasStation: station.id))
                            .padding(10)
                            //.resizable()
                            .scaledToFit()
                            .frame(width: viewModel.expandedItem == station.id ? 40 : 28, height: viewModel.expandedItem == station.id ? 40 : 28)
                        /*
                            
                            .border(width: viewModel.expandedItem == station.id ? 20 : 0)
                         */
                    }
                    //VStack {}
                })
            }
             
        }
        .selectionDisabled(false)
        .ignoresSafeArea(.all)
        .mapStyle(.standard(showsTraffic: true))
        .onTapGesture {
            withAnimation(.spring()) {
                viewModel.hideMenus()
                viewModel.setCardState(height: .NEUTRAL)
            }
        }//)
    }
}

// Initially, the app won't contain any form on monetization. However, future updates
// might implement this feature.
/*
struct CoffeButton: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    
    var body: some View {
        Button(action: {
            withAnimation(.spring) {
                if !viewModel.isCoffeeMenuVisible {
                    viewModel.hideFilters()
                }
                
                viewModel.isCoffeeMenuVisible.toggle()
            }
        }) {
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .padding()
                    .tint(Color.white)
                    .font(.system(size: 20))
            }
            .background(Color("TranslucidBackgroundColor")
            .cornerRadius(50)
            .frame(width: 30, height: 30)
            
            Spacer()
        }
        .offset(x: 35, y: 120)
    }
}
 

 struct CoffeeView: View {
     @EnvironmentObject var viewModel: DondeGasViewModel
     
     var body: some View {
         VStack (alignment: .center) {
             Spacer()
             Text("¿Te gusta DondeGas?")
                 .font(.title)
                 .bold()
             Text("Sin anuncios es todavía mejor ")
                 .font(.title3)
             
             Text("Este desarrollador necesita más café para seguir mejorando la aplicación.\n\nSi me invitas a uno, no verás más anuncios en DondeGas.")
                 .font(.callout)
                 .multilineTextAlignment(.center)
                 .padding()
                 .padding(.horizontal, 20)
                 .padding(.top, 20)
             
             
             Spacer()
             
             Button(action: {
                 // Lógica de Apple Pay para el pago
                 viewModel.launchCoffeePayment()
             }) {
                 HStack {
                     Text("Trato hecho ")
                         .fontWeight(.heavy)
                         .font(.system(size: 22))
                     Image(systemName: "cup.and.saucer")
                         .tint(Color.white)
                         .font(.system(size: 25))
                 }
                 .padding()
             }
             .background(LinearGradient(gradient: Gradient(colors: [Color.brown, Color.black.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
             .cornerRadius(25)
             .shadow(color: .gray.opacity(0.7), radius: 8, x: -8, y: -8)
             .shadow(color: .gray.opacity(0.5), radius: 8, x: 8, y: 8)
             Spacer()
         }
         .frame(width: 350, height: 500)
         .background(Color("TranslucidBackgroundColor")
         .cornerRadius(10)
         .shadow(radius: 5)
         .offset(x: viewModel.isCoffeeMenuVisible ? 20 : -350, y: 100)
         .opacity(viewModel.isCoffeeMenuVisible ? 1 : 0)
     }
 }
 
*/

struct FuelMenuCardView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(FuelType.allCases, id: \.self) { fuelType in
                        Button(action: {
                            viewModel.selectedFuelType = fuelType
                            
                            withAnimation(.spring()) {
                                viewModel.isFuelMenuVisible = false
                            }
                            
                            viewModel.filterGasStations()
                        }) {
                            HStack {
                                Text(viewModel.fuelTypeToCommercialName(fuelType: fuelType))
                                    .bold()
                                Spacer()
                                Image(systemName: "fuelpump.fill")
                            }
                            .padding(.horizontal, 35)
                            .padding(.vertical, 12)
                            .foregroundStyle(viewModel.getFuelTypeColor(fuelType: fuelType))
                        }
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                }
            }
            .padding(.top, 18)
        }
        .frame(width: 300, height: viewModel.isFuelMenuVisible ? 300 : 0)
        .background(Color("TranslucidBackgroundColor"))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(viewModel.isFuelMenuVisible ? 1 : 0)
        .offset(y: (viewModel.isFuelMenuVisible ? -5 : 150) + viewModel.slidingCardOffset.height)
    }
}


struct LocationMenuCardView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @State private var distance: Double = 5
    @StateObject var locationManager = LocationManager.shared
    @State private var showingSearchSheet = false
    
    var body: some View {
        VStack {
            Picker("Selecciona un modo de búsqueda", selection: $viewModel.usingCustomLocation) {
                Text(NSLocalizedString("Tu ubicación", comment: "")).tag(false)
                Text(NSLocalizedString("Búsqueda", comment: "")).tag(true)
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: viewModel.usingCustomLocation) {
                if !viewModel.usingCustomLocation {
                    locationManager.setRealUserLocation()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.filterGasStations()
                }
            }
            
            Spacer()
            
            if viewModel.usingCustomLocation {
                VStack {
                    Text(NSLocalizedString("Ubicación seleccionada", comment: ""))
                        .font(.system(size: 16))
                    HStack {
                        Image(systemName: "location.magnifyingglass")
                            .foregroundStyle(.blue)
                            .padding()
                            .padding(.trailing, -10)
                        Text("\(locationManager.locationName)")
                            .font(.system(size: 22))
                            .fontWeight(.semibold)
                            .padding()
                            .padding(.leading, -10)
                            .multilineTextAlignment(.leading)
                    }
                    .background(.thickMaterial)
                    .backgroundStyle(.white.opacity(0.4))
                    .cornerRadius(50)
                    .onTapGesture {
                        showingSearchSheet = true
                    }
                    .sheet(isPresented: $showingSearchSheet) {
                        LocationSearchView(isPresented: $showingSearchSheet)
                    }
                }
                Spacer(minLength: 20)
                HStack {
                    Text (NSLocalizedString("Estaciones a", comment: ""))
                        .font(.system(size: 18))
                    Text(String(Int($distance.wrappedValue)))
                        .font(.system(size: 18))
                        .bold()
                        .foregroundStyle(Color.blue)
                    Text(viewModel.reachLimit > 1 ? String(format: NSLocalizedString("kms de %@", comment: ""), locationManager.locationName) : String(format: NSLocalizedString("km de %@", comment: ""), locationManager.locationName))
                        .font(.system(size: 18))
                }
                
                Slider(
                    value: $distance,
                    in: 0...100,
                    step: 5,
                    onEditingChanged: { editing in
                        viewModel.reachLimit = Int($distance.wrappedValue)
                        viewModel.filterGasStations()
                    }
                )
                .tint(Color.blue)
                .frame(width: 210)
                
                Spacer()
            } else {
                VStack {
                    Text(NSLocalizedString("Ubicación actual", comment: ""))
                        .font(.system(size: 16))
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                        Text("\(locationManager.locationName)")
                            .font(.system(size: 26))
                        .fontWeight(.bold)                }
                }
                
                Spacer(minLength: 20)
                
                HStack {
                    Text (NSLocalizedString("Estaciones a", comment: ""))
                        .font(.system(size: 18))
                    Text(String(Int($distance.wrappedValue)))
                        .font(.system(size: 18))
                        .bold()
                        .foregroundStyle(Color.blue)
                    Text(viewModel.reachLimit > 1 ? NSLocalizedString("km de ti", comment: "") : NSLocalizedString("kms de ti", comment: ""))
                        .font(.system(size: 18))
                }
                
                Slider(
                    value: $distance,
                    in: 0...100,
                    step: 5,
                    onEditingChanged: { editing in
                        viewModel.reachLimit = Int($distance.wrappedValue)
                        viewModel.filterGasStations()
                    }
                )
                .tint(Color.blue)
                .frame(width: 210)
                
                Spacer()
            }
        }
        .frame(width: 300, height: viewModel.isLocationMenuVisible ? 300 : 0)
        .background(Color("TranslucidBackgroundColor"))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(viewModel.isLocationMenuVisible ? 1 : 0)
        .offset(y: (viewModel.isLocationMenuVisible ? -5 : 150) + viewModel.slidingCardOffset.height)
    }
}

struct FilterButtons: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @StateObject var locationManager = LocationManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // Fuel type menu button
            Button(action: {
                withAnimation(.spring()) {
                    if viewModel.latestCardState == .EXPANDED {
                        viewModel.setCardState(height: .NEUTRAL)
                    }
                    
                    viewModel.isFuelMenuVisible.toggle()
                    viewModel.isLocationMenuVisible = false
                }
            }) {
                HStack {
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size:24))
                        .padding(.leading, 12)
                    Text(viewModel.fuelTypeToCommercialName(fuelType: viewModel.selectedFuelType))
                }
            }
            .clipped()
            .frame(width: 150, height: 60, alignment: .leading)
            .cornerRadius(10, corners: [.topLeft, .bottomLeft])
            .background(Color("TranslucidBackgroundColor"))
            .foregroundColor(viewModel.getFuelTypeColor(fuelType: viewModel.selectedFuelType))
            .multilineTextAlignment(.leading)
            
            // Location menu button
            Button(action: {
                withAnimation(.spring()) {
                    if viewModel.latestCardState == .EXPANDED {
                        viewModel.setCardState(height: .NEUTRAL)
                    }
                    
                    viewModel.isLocationMenuVisible.toggle()
                    viewModel.isFuelMenuVisible = false
                }
            }) {
                HStack {
                    Text("\(locationManager.locationName)")
                    Image(systemName: "location.fill")
                        .font(.system(size:24))
                        .padding(.trailing, 12)
                }
            }
            .clipped()
            .frame(width: 150, height: 60, alignment: .trailing)
            .cornerRadius(10, corners: [.topRight, .bottomRight])
            .background(Color("TranslucidBackgroundColor"))
            .foregroundColor(viewModel.getFuelTypeColor(fuelType: viewModel.selectedFuelType))
            .multilineTextAlignment(.leading)
        }
        .clipped()
        .cornerRadius(10)
        .offset(y: viewModel.slidingCardOffset.height)
    }
}

struct SlidingCardView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @GestureState private var dragState = DragState.inactive
    @StateObject var locationManager = LocationManager.shared
    
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 70, height: 5)
                .background(Color("TranslucidBackgroundColor"))
                .padding(.top, 8)
                .padding(.horizontal, 100)
                .zIndex(1)
                .gesture(dragGesture)
            
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView(NSLocalizedString("Buscando los mejores precios", comment: ""))
                        .padding(.bottom, 50)
                    Spacer()
                }
                .padding(.bottom, 380)
            } else if !viewModel.errorMessage.isEmpty {
                VStack {
                    Spacer()
                    Text(NSLocalizedString("¡Vaya! Parece que ha habido un error", comment: ""))
                        .padding(.bottom, 3)
                        .frame(alignment: .center)
                        .bold()
                        .font(.system(size: 20))
                    Text(NSLocalizedString("Comprueba tu conexión y vuelve a intentarlo", comment: ""))
                        .padding(.top, 0)
                        .padding(.bottom, 10)
                        .frame(alignment: .center)
                        .font(.system(size: 16))
                        .foregroundStyle(.gray)
                    Button(action: {
                        viewModel.loadGasStations()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise") // Ícono de reintentar
                            Text(NSLocalizedString("Reintentar", comment: ""))
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding(.bottom, 200)
            } else {
                Spacer()
                HStack {
                    if viewModel.usingCustomLocation {
                        Text(String(format: NSLocalizedString("Estaciones cerca de %@", comment: ""), locationManager.locationName))
                            .font(.system(size: 26, weight: .heavy))
                            .fontDesign(.rounded)
                            .padding(.top, 10)
                            .padding(.bottom, 25)
                            .multilineTextAlignment(.center)
                        
                    } else {
                        Text(NSLocalizedString("Estaciones cerca de ti", comment: ""))
                            .font(.system(size: 26, weight: .heavy))
                            .fontDesign(.rounded)
                            .padding(.top, 10)
                            .padding(.bottom, 25)
                    }
                    
                }
                Spacer()
                
                if viewModel.gasStations.isEmpty {
                    VStack {
                        Text(
                            viewModel.reachLimit > 1 ?
                                String(format: NSLocalizedString("No se han encontrado estaciones a %d kms de aquí", comment: ""),viewModel.reachLimit) :
                                String(format: NSLocalizedString("No se han encontrado estaciones a %d km de aquí", comment: ""), viewModel.reachLimit))
                            .font(.system(size: 22, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                        
                        Text(NSLocalizedString("Prueba a aumentar el radio de búsqueda en el menú de ubicación", comment: ""))
                            .font(.system(size: 16, weight: .regular))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 20)
                            .padding(.top, 3)
                        Spacer()
                    }
                } else {
                    ScrollViewReader { scrollView in
                        List(viewModel.gasStations) { station in
                            Button(action: {
                                if viewModel.expandedItem == station.id {
                                    viewModel.expandedItem = ""
                                    locationManager.focusOnUser()
                                } else {
                                    viewModel.expandedItem = station.id
                                    locationManager.setLocation(latitude: station.latitude, longitude: station.longitude)
                                }
                            }) {
                                Spacer()
                                if viewModel.expandedItem == station.id {
                                    HStack {
                                        VStack (alignment: .leading) {
                                            HStack {
                                                Text(station.name)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .multilineTextAlignment(.leading)
                                                    .foregroundStyle(Color("TextColor"))
                                                Text((station.prices[viewModel.selectedFuelType] ?? "0.000") ?? "0.000")
                                                    .font(.footnote)
                                                    .foregroundStyle(viewModel.getColorCode(gasStation: station.id))
                                            }
                                            Text("A \(String(format:"%.2f" , locationManager.distanceToGasStation(station: station))) km.")
                                                .font(.subheadline)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                            Button(action: {
                                                if let stationLatitude = Double(station.latitude), let stationLongitude = Double(station.longitude) {
                                                    let coordinate = CLLocationCoordinate2DMake(stationLatitude, stationLongitude)
                                                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
                                                    mapItem.name = NSLocalizedString("Prueba a aumentar el radio de búsqueda en el menú de ubicación", comment: "")
                                                    mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
                                                }
                                            }) {
                                                HStack {
                                                    Image(systemName: "car.fill")
                                                    Text(NSLocalizedString("Ruta hasta allí", comment: ""))
                                                }
                                            }
                                            .foregroundStyle(Color.blue)
                                            .cornerRadius(10)
                                        }.gridColumnAlignment(.leading)
                                        Spacer()
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Text(viewModel.getOpenStatus(scheduleString: station.schedule))
                                                    .font(.callout)
                                                    .foregroundStyle(viewModel.getOpenStatus(scheduleString: station.schedule).hasPrefix(NSLocalizedString("Abierto", comment: "")) ? .green : .red)
                                                    .multilineTextAlignment(.trailing)
                                                    .padding(.bottom, 5)
                                            }
                                            HStack {
                                                Spacer()
                                                Text(viewModel.getSchedule(scheduleString: station.schedule))
                                                    .font(.footnote)
                                                    .multilineTextAlignment(.trailing)
                                                    .foregroundStyle(Color("TextColor"))
                                            }
                                        }.frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                } else {
                                    HStack {
                                        VStack (alignment: .leading) {
                                            HStack {
                                                Text(station.name)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .multilineTextAlignment(.leading)
                                                    .foregroundStyle(Color("TextColor"))
                                                Text((station.prices[viewModel.selectedFuelType] ?? "0.000") ?? "0.000")
                                                    .font(.footnote)
                                                    .foregroundStyle(viewModel.getColorCode(gasStation: station.id))
                                            }
                                            Text("A \(String(format:"%.2f" , locationManager.distanceToGasStation(station: station))) km.")
                                                .font(.subheadline)
                                                .multilineTextAlignment(.leading)
                                        }.gridColumnAlignment(.leading)
                                        Spacer()
                                        VStack {
                                            Text(viewModel.getOpenStatus(scheduleString: station.schedule))
                                                .font(.callout)
                                                .multilineTextAlignment(.trailing)
                                                .foregroundStyle(viewModel.getOpenStatus(scheduleString: station.schedule).hasPrefix(NSLocalizedString("Abierto", comment: "")) ? .green : .red)
                                        }.frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                    .contentShape(Rectangle()) // Making the whole HStack clickable.
                                    .background(Color.clear)
                                }
                                Spacer()
                            }
                        }
                        .listStyle(.automatic)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.top, -18)
                        .onChange(of: viewModel.expandedItem) {
                            withAnimation(.easeInOut(duration: 1.2)) {
                                scrollView.scrollTo(viewModel.expandedItem, anchor: .top)
                            }
                        }
                    }
                    
                    Text(String(format: NSLocalizedString("Datos facilitados por el Ministerio para la Transición Ecológica y Reto Demográfico. \n Fecha de recuperación: %@", comment: ""), viewModel.collectionDate))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 70)
                        .font(.footnote)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                }
            }
        }
        .frame(height: 600)
        .frame(maxWidth: .infinity)
        .background(Color("TranslucidBackgroundColor"))
        .cornerRadius(10)
        .shadow(radius: 5)
        .offset(y: viewModel.slidingCardOffset.height)
        .edgesIgnoringSafeArea(.bottom)
        .animation(.interactiveSpring(), value: dragState.translation)
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                withAnimation {
                    if gesture.translation.height > 0 {
                        //print("Actuando")
                        viewModel.slidingCardOffset.height = gesture.translation.height
                    } else {
                        viewModel.slidingCardOffset.height = 0
                    }
                    //print("Current height: \(gesture.translation.height)")
                    
                }
            }
            .onEnded { drag in
                withAnimation {
                    viewModel.setCardState(movement: viewModel.slidingCardOffset)
                }
            }
    }
    
    enum DragState {
        case inactive
        case dragging(translation: CGSize)
        
        var translation: CGSize {
            switch self {
            case .inactive:
                return .zero
            case .dragging(let translation):
                return translation
            }
        }
        
        var isDragging: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct LocationSearchView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @Binding var isPresented: Bool
    @StateObject var locationManager = LocationManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                TextField(NSLocalizedString("Busca ciudades, pueblos, calles...", comment: ""), text: $viewModel.locationSearchQuery)
                    .padding()
                    .background(.black.opacity(0.7))
                    .cornerRadius(50)
                    .foregroundStyle(.white)
                    .padding()
                
                List(viewModel.searchResults, id: \.self) { result in
                    HStack {
                        Text("\(result.title), \(result.subtitle)")
                        Spacer()
                    }
                    .onTapGesture {
                        locationManager.setCustomUserLocation(target: result)
                        isPresented = false
                    }
                    
                    
                }
            }
            .navigationBarTitle(NSLocalizedString("Buscar ubicación personalizada", comment: ""), displayMode: .inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("Cerrar", comment: "")) {
                isPresented = false
            })
        }
        .onDisappear {
            withAnimation {
                viewModel.hideFilters()
            }
            viewModel.loadGasStations()
            
        }
    }
}




