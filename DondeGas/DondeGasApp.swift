import SwiftUI
import MapKit
import CoreLocation

fileprivate var palette: ColorPalette = ColorPalette()

@main
struct DondeGasApp: App {
    @StateObject var viewModel = DondeGasViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .accentColor(Color.white)
        }
    }
}

enum CardState {
    case collapsed
    case halfExpanded
    case fullyExpanded
}

struct ContentView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @State private var cardState: CardState = .halfExpanded
    @Environment(\.colorScheme) var colorScheme
    @StateObject var locationManager = LocationManager.shared
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Map(coordinateRegion: $locationManager.region, showsUserLocation: !viewModel.usingCustomLocation, annotationItems: viewModel.gasStationLocations) {gasStation in
                //MapMarker(coordinate: gasStation.location, tint: viewModel.getColorCode(gasStation: gasStation.id))
                MapAnnotation(coordinate: gasStation.location) {
                    Image(systemName: "fuelpump.circle")
                        .resizable()
                        .frame(width: viewModel.expandedItem == gasStation.id ? 45 : 30, height: viewModel.expandedItem == gasStation.id ? 45 : 30)
                        .foregroundStyle(viewModel.getColorCode(gasStation: gasStation.id))
                        .onTapGesture {
                            // Definir nuevo expandedItem
                            viewModel.expandedItem = gasStation.id
                        }
                }
            }
            .ignoresSafeArea(.all)
            .mapStyle(.standard(showsTraffic: true))
            .onTapGesture {
                withAnimation(.spring()) {
                    viewModel.hideMenus()
                }
            }
            
            Button(action: {
                if !viewModel.isCoffeeMenuVisible {
                    withAnimation(.spring) {
                        viewModel.hideFilters()
                    }
                }
                                
                withAnimation(.spring) {
                    viewModel.isCoffeeMenuVisible.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .padding()
                        .tint(Color.white)
                        .font(.system(size: 20))
                }
                .background(palette.backgroundColor)
                .cornerRadius(50)
                .frame(width: 30, height: 30)
                Spacer()
            }
            .offset(x: 35, y: cardState == .fullyExpanded ? 220 : 15)

            VStack {
                
                Spacer()
            
                // Filtros
                ZStack {
                    FuelMenuCardView()
                    LocationMenuCardView()
                }
                
                
                // Botones de filtros
                HStack(spacing: 0) {
                    // Menú de tipo de combustible
                    Button(action: {
                        if cardState == .fullyExpanded {
                            withAnimation(.spring()) {
                                cardState = .halfExpanded
                            }
                        }
                        withAnimation(.spring()) {
                            viewModel.isFuelMenuVisible.toggle()
                            viewModel.isLocationMenuVisible = false
                            viewModel.isCoffeeMenuVisible = false
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
                    .background(palette.backgroundColor)
                    .foregroundColor(viewModel.getFuelTypeColor(fuelType: viewModel.selectedFuelType))
                    .multilineTextAlignment(.leading)
                    
                    Button(action: {
                        if cardState == .fullyExpanded {
                            withAnimation(.spring()) {
                                cardState = .halfExpanded
                            }
                        }
                        
                        withAnimation(.spring()) {
                            viewModel.isLocationMenuVisible.toggle()
                            viewModel.isFuelMenuVisible = false
                            viewModel.isCoffeeMenuVisible = false
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
                    .background(palette.backgroundColor)
                    .foregroundColor(viewModel.getFuelTypeColor(fuelType: viewModel.selectedFuelType))
                    .multilineTextAlignment(.leading)
                }
                .clipped()
                .cornerRadius(10)

                // Tarjeta deslizante
                SlidingCardView(cardState: $cardState)
                    .edgesIgnoringSafeArea(.all)
            }
            
            HereComesTheMoneyView()
        }
        .onAppear {
            viewModel.loadGasStations()
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct FuelMenuCardView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @Environment(\.colorScheme) var colorScheme

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
        .frame(width: 300, height: 300)
        .background(palette.backgroundColor)
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(viewModel.isFuelMenuVisible ? 1 : 0)
        .offset(y: viewModel.isFuelMenuVisible ? -5 : 375 )
    }
}


struct LocationMenuCardView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var distance: Double = 5
    @StateObject var locationManager = LocationManager.shared
    @State private var showingSearchSheet = false
    
    var body: some View {
        VStack {
            Picker("Selecciona un modo de búsqueda", selection: $viewModel.usingCustomLocation) {
                Text("Tu ubicación").tag(false)
                Text("Búsqueda").tag(true)
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
                    Text("Ubicación seleccionada")
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
                    Text ("Estaciones a")
                        .font(.system(size: 18))
                    Text(String(Int($distance.wrappedValue)))
                        .font(.system(size: 18))
                        .bold()
                        .foregroundStyle(Color.blue)
                    Text(viewModel.reachLimit > 1 ? "km de \(locationManager.locationName)" : "kms de \(locationManager.locationName)")
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
                    Text("Ubicación actual")
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
                    Text ("Estaciones a")
                        .font(.system(size: 18))
                    Text(String(Int($distance.wrappedValue)))
                        .font(.system(size: 18))
                        .bold()
                        .foregroundStyle(Color.blue)
                    Text(viewModel.reachLimit > 1 ? "km de ti" : "kms de ti")
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
        .frame(width: 300, height: 300)
        .background(palette.backgroundColor)
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(viewModel.isLocationMenuVisible ? 1 : 0)
        .offset(y: viewModel.isLocationMenuVisible ? -5 : 375 )
    }
}

struct SlidingCardView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var cardState: CardState
    @GestureState private var dragState = DragState.inactive
    @StateObject var locationManager = LocationManager.shared
    
    
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 40, height: 5)
                .background(palette.backgroundColor)
                .padding(.top, 8)
                .zIndex(1) // Asegura que el RoundedRectangle se mantiene en la capa superior
            
            if viewModel.isLoading {
                Spacer()
                ProgressView("Cargando datos...")
                Spacer()
                
            } else if !viewModel.errorMessage.isEmpty {
                Spacer()
                Text("¡Vaya! Parece que ha habido un error")
                    .padding(.bottom, 3)
                    .frame(alignment: .center)
                    .bold()
                    .font(.system(size: 20))
                Text("Comprueba tu conexión y vuelve a intentarlo")
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
                        Text("Reintentar")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                Spacer()
            } else {
                Spacer()
                HStack {
                    if viewModel.usingCustomLocation {
                        Text("Estaciones cerca de \(locationManager.locationName)")
                            .font(.system(size: 26, weight: .heavy))
                            .fontDesign(.rounded)
                            .padding(.top, 10)
                            .padding(.bottom, 25)
                            .multilineTextAlignment(.center)
                        
                    } else {
                        Text("Estaciones cerca de ti")
                            .font(.system(size: 26, weight: .heavy))
                            .fontDesign(.rounded)
                            .padding(.top, 10)
                            .padding(.bottom, 25)
                    }
                    
                }
                Spacer()
                
                if viewModel.gasStations.isEmpty {
                    VStack {
                        Text("No se han encontrado estaciones a \(viewModel.reachLimit) \(viewModel.reachLimit > 1 ? "kms" : "km") de aquí")
                            .font(.system(size: 22, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                    
                        Text("Prueba a aumentar el radio de búsqueda en el menú de ubicación")
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
                                                    mapItem.name = "Abrir en Maps"
                                                    mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
                                                }
                                            }) {
                                                HStack {
                                                    Image(systemName: "car.fill")
                                                    Text("Ruta hasta allí")
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
                                                    .foregroundStyle(viewModel.getOpenStatus(scheduleString: station.schedule).hasPrefix("Abierto") ? .green : .red)
                                                    .multilineTextAlignment(.trailing)
                                                    .padding(.bottom, 5)
                                            }
                                            HStack {
                                                Spacer()
                                                Text(viewModel.getSchedule(scheduleString: station.schedule))
                                                    .font(.footnote)
                                                    .multilineTextAlignment(.trailing)
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
                                                .foregroundStyle(viewModel.getOpenStatus(scheduleString: station.schedule).hasPrefix("Abierto") ? .green : .red)
                                        }.frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                    .contentShape(Rectangle()) // Esto hace que todo el HStack sea "clickable"
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
                }
            }
        }
        .frame(height: cardHeight(for: cardState) + dragState.translation.height)
        .frame(maxWidth: .infinity)
        .background(palette.backgroundColor)
        .cornerRadius(10)
        .shadow(radius: 5)
        .gesture(dragGesture)
        .edgesIgnoringSafeArea(.bottom)
        .animation(.interactiveSpring(), value: dragState.translation)
        .onChange(of: viewModel.isCoffeeMenuVisible) {
            if viewModel.isCoffeeMenuVisible {
                withAnimation {
                    cardState = .collapsed
                }
            } else {
                withAnimation {
                    cardState = .halfExpanded
                }
            }
        }
    }
    
    // Ajustar la función cardHeight para que coincida con las alturas deseadas
    private func cardHeight(for state: CardState) -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let topSafeAreaHeight = (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
        let bottomSafeAreaHeight = (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0)
        let usableScreenHeight = screenHeight - topSafeAreaHeight - bottomSafeAreaHeight
        
        // Se añade un factor de correción a cada posición
        switch state {
        case .collapsed:
            return bottomSafeAreaHeight * 2.5
        case .halfExpanded:
            return usableScreenHeight * 0.45
        case .fullyExpanded:
            return (screenHeight - topSafeAreaHeight)
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .updating($dragState) { drag, state, transaction in
                state = .dragging(translation: drag.translation)
            }
            .onEnded { drag in
                withAnimation(.spring()) {
                    let verticalMovement = drag.translation.height / cardHeight(for: cardState)
                    if cardState == .collapsed && verticalMovement < -0.25 {
                        cardState = .halfExpanded
                    } else if cardState == .halfExpanded {
                        if verticalMovement > 0.25 {
                            cardState = .collapsed
                        } else if verticalMovement < -0.25 {
                            viewModel.hideMenus()
                            cardState = .fullyExpanded
                        }
                    } else if cardState == .fullyExpanded && verticalMovement > 0.25 {
                        cardState = .halfExpanded
                    }
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

struct HereComesTheMoneyView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @Environment(\.colorScheme) var colorScheme
    
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
        .background(palette.backgroundColor)
        .cornerRadius(10)
        .shadow(radius: 5)
        .offset(x: viewModel.isCoffeeMenuVisible ? 20 : -350, y: 100)
        .opacity(viewModel.isCoffeeMenuVisible ? 1 : 0)
    }
}

struct LocationSearchView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @Binding var isPresented: Bool

    @StateObject var locationManager = LocationManager.shared
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Busca ciudades, pueblos, calles...", text: $viewModel.locationSearchQuery)
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
            .navigationBarTitle("Buscar ubicación personalizada", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cerrar") {
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




