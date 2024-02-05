import SwiftUI
import MapKit
import CoreLocation
import StoreKit

import WebKit

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
                HStack {
                    InfoMenu()
                    Spacer()
                }
                //Spacer()
                
                // Filters
                ZStack {
                    TutorialView()
                    FuelMenuCardView()
                    LocationMenuCardView()
                }
                
                Spacer()
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
        Map(position: $locationManager.mapPosition) {
            UserAnnotation()
            ForEach(viewModel.gasStationLocations, id: \.id) { station in
                Annotation( "", coordinate: station.location, anchor: .center, content: {
                    Button(action: {
                        viewModel.expandedItem = station.id
                    }) {
                        Image(systemName: "fuelpump.circle.fill")
                            .foregroundColor(viewModel.getColorCode(gasStation: station.id))
                            .padding(10)
                    }
                    .scaleEffect(viewModel.expandedItem == station.id ? 1.8 : 1)
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
        }
    }
}

struct InfoMenu: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @Environment(\.requestReview) var requestReview
    @State private var showingMail = false
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        ZStack {
            if viewModel.isInfoMenuVisible {
                VStack(alignment: .center) {
                    HStack {
                        Button(action: {
                            withAnimation {
                                viewModel.isInfoMenuVisible = false
                            }
                        }) {
                            Image(systemName: "x.circle")
                                .padding(.leading)
                                .tint(Color("TextColor"))
                                .font(.system(size: 28))
                        }
                        Spacer()
                    }
                    .onTapGesture {
                        withAnimation {
                            if !viewModel.isInfoMenuVisible {
                                viewModel.hideFilters()
                                viewModel.setCardState(height: .NEUTRAL)
                            }
                            
                            viewModel.isInfoMenuVisible.toggle()
                        }
                    }
                    
                    HStack {
                        Button("Contacto y soporte") {
                            showingMail = true
                        }
                        .sheet(isPresented: $showingMail) {
                            MailView(recipient: "dondegasapp@gmail.com", subject: "Consulta", body: "Escribe tu mensaje aquí.")
                        }
                    }
                    .frame(width: 280, height: 60)
                    .background(Color("BackgroundGray"))
                    .foregroundStyle(Color("TextColor"))
                    .cornerRadius(50)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    
                   
                    HStack {
                        Button("Valora DondeGas") {
                            requestReview()
                        }
                    }
                    .frame(width: 280, height: 60)
                    .background(Color("BackgroundGray"))
                    .foregroundStyle(Color("TextColor"))
                    .cornerRadius(50)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    
                    
                    HStack {
                        Button("Política de Privacidad") {
                            showingPrivacyPolicy = true
                        }
                        .sheet(isPresented: $showingPrivacyPolicy) {
                            PrivacyPolicyView()
                        }
                    }
                    .frame(width: 280, height: 60)
                    .background(Color("BackgroundGray"))
                    .foregroundStyle(Color("TextColor"))
                    .cornerRadius(50)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                    Spacer()
                    
                    Text(String(format: NSLocalizedString("Datos facilitados por el Ministerio para la Transición Ecológica y Reto Demográfico. \n Actualizados el %@", comment: ""), viewModel.collectionDate))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 15)
                        .font(.footnote)
                }
                .padding(.top, 20)
            } else {
                HStack {
                    Image(systemName: "info")
                        .padding()
                        .tint(Color("TextColor"))
                        .font(.system(size: 22))
                }
                .onTapGesture {
                    withAnimation {
                        if !viewModel.isInfoMenuVisible {
                            viewModel.hideFilters()
                            viewModel.setCardState(height: .NEUTRAL)
                        }
                        
                        viewModel.isInfoMenuVisible.toggle()
                    }
                }
            }
        }
        .shadow(radius: 5)
        .opacity(1)
        .transition(.scale)
        .frame(width: viewModel.isInfoMenuVisible ? 350 : 50, height: viewModel.isInfoMenuVisible ? 420 : 50)
        .background(viewModel.isInfoMenuVisible ? Color("DarkerTranslucidBackgroundColor") : Color("TranslucidBackgroundColor"))
        .cornerRadius(viewModel.isInfoMenuVisible ? 10 : 50)
        .offset(x: 22, y: viewModel.isInfoMenuVisible ? 300 : 120)
    }
}

struct FuelMenuCardView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(FuelType.allCases, id: \.self) { fuelType in
                        Button(action: {
                            viewModel.selectedFuelType = fuelType
                            UserDefaultsManager.shared.selectedFuelType = fuelType
                            
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
        .background(Color("DarkerTranslucidBackgroundColor"))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(viewModel.isFuelMenuVisible ? 1 : 0)
        .offset(y: (viewModel.isFuelMenuVisible ? -5 : 150) + viewModel.slidingCardOffset)
    }
}

struct LocationMenuCardView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @State private var distance: Double = Double(UserDefaultsManager.shared.userDefinedRange)
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
                viewModel.updateUserPreferences()
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
                    Text(String(Int($distance.wrappedValue) == 0 ? 5 : Int($distance.wrappedValue)))
                        .font(.system(size: 18))
                        .bold()
                        .foregroundStyle(Color.blue)
                    Text(viewModel.reachLimit > 1 ? String(format: NSLocalizedString("kms de %@", comment: ""), locationManager.locationName) : String(format: NSLocalizedString("km de %@", comment: ""), locationManager.locationName))
                        .font(.system(size: 18))
                }
                
                Slider(
                    value: $distance,
                    in: 5...100,
                    step: 5,
                    onEditingChanged: { editing in
                        viewModel.reachLimit = Int($distance.wrappedValue)
                        UserDefaultsManager.shared.userDefinedRange = Int($distance.wrappedValue)
                        
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
                    Text(String(Int($distance.wrappedValue) == 0 ? 5 : Int($distance.wrappedValue)))
                        .font(.system(size: 18))
                        .bold()
                        .foregroundStyle(Color.blue)
                    Text(viewModel.reachLimit > 1 ? NSLocalizedString("km de ti", comment: "") : NSLocalizedString("kms de ti", comment: ""))
                        .font(.system(size: 18))
                }
                
                Slider(
                    value: $distance,
                    in: 5...100,
                    step: 5,
                    onEditingChanged: { editing in
                        viewModel.reachLimit = Int($distance.wrappedValue)
                        UserDefaultsManager.shared.userDefinedRange = Int($distance.wrappedValue)
                        
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
        .offset(y: (viewModel.isLocationMenuVisible ? -5 : 150) + viewModel.slidingCardOffset)
    }
}

struct FilterButtons: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @StateObject var locationManager = LocationManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // Fuel type menu button
            Button(action: {
                withAnimation(.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0)) {
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
                        .multilineTextAlignment(.leading)
                }
            }
            .clipped()
            .frame(width: 150, height: 60, alignment: .leading)
            .cornerRadius(10, corners: [.topLeft, .bottomLeft])
            .background(Color("TranslucidBackgroundColor"))
            .foregroundColor(viewModel.getFuelTypeColor(fuelType: viewModel.selectedFuelType))
            
            // Location menu button
            Button(action: {
                withAnimation(.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0)) {
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
        .offset(y: viewModel.slidingCardOffset)
    }
}

struct SlidingCardView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @StateObject var locationManager = LocationManager.shared
    @GestureState private var dragState = DragState.inactive
    @State var position = CardPosition.bottom
    
    enum CardPosition: CGFloat {
        case top = 100
        case middle = 380
        case bottom = 600
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
    
    var body: some View {
        
        let drag = DragGesture()
                    .updating($dragState) { drag, state, transaction in
                        state = .dragging(translation: drag.translation)
                        viewModel.slidingCardOffset = self.position.rawValue + drag.translation.height
                    }
                    .onEnded(onDragEnded)
        
        VStack {
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 40, height: 5)
                .background(Color("TranslucidBackgroundColor"))
                .padding(.top, 8)
                .padding(.horizontal, 100)
                .zIndex(1)
            
            if viewModel.isLoading {
                VStack {
                    ProgressView(NSLocalizedString("Buscando los mejores precios", comment: ""))
                        .padding(.top, 40)
                    Spacer()
                }
                .padding(.bottom, 200)
                .onAppear(perform: { setCardPosition(height: .bottom) })
            } else if !viewModel.errorMessage.isEmpty {
                VStack {
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
                .padding(.top, 40)
                .onAppear(perform: { setCardPosition(height: .middle) })
            } else {
                HStack {
                    if viewModel.usingCustomLocation {
                        Text(String(format: NSLocalizedString("Estaciones cerca de %@", comment: ""), locationManager.locationName))
                            .font(.system(size: 24, weight: .heavy))
                            .fontDesign(.rounded)
                            .padding(.top, 10)
                            .padding(.bottom, 25)
                            .padding(.horizontal, 15)
                            .multilineTextAlignment(.center)
                        
                    } else {
                        Text(NSLocalizedString("Estaciones cerca de ti", comment: ""))
                            .font(.system(size: 26, weight: .heavy))
                            .fontDesign(.rounded)
                            .padding(.top, 10)
                            .padding(.bottom, 25)
                    }
                    
                }
                
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
                    .onAppear(perform: { setCardPosition(height: .middle) })
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
                                                if let stationLatitude = Double(station.latitude.replacingOccurrences(of: ",", with: ".")), let stationLongitude = Double(station.longitude.replacingOccurrences(of: ",", with: ".")) {
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
                        .frame(height: position == CardPosition.middle ? 290 : 580)
                        .padding(.top, 2)
                        .onChange(of: viewModel.expandedItem) {
                            withAnimation(.easeInOut(duration: 1.2)) {
                                scrollView.scrollTo(viewModel.expandedItem, anchor: .top)
                            }
                        }
                        .onAppear(perform: { setCardPosition(height: .middle) })
                    }
                    .padding(.top, -20)
                }
            }
            Spacer()
        }
        .frame(height: UIScreen.main.bounds.height)
        .frame(maxWidth: .infinity)
        .background(Color("TranslucidBackgroundColor"))
        .cornerRadius(10)
        .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.13), radius: 10.0)
        .offset(y: self.position.rawValue + self.dragState.translation.height)
        .edgesIgnoringSafeArea(.bottom)
        .animation(self.dragState.isDragging ? nil : .interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0))
        .gesture(drag)
    }
    
    private func setCardPosition(height: CardPosition) {
        withAnimation(.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0)) {
            self.position = height
            viewModel.slidingCardOffset = height.rawValue
        }
    }
    
    private func onDragEnded(drag: DragGesture.Value) {
        let verticalDirection = drag.predictedEndLocation.y - drag.location.y
        let cardTopEdgeLocation = self.position.rawValue + drag.translation.height
        let positionAbove: CardPosition
        let positionBelow: CardPosition
        let closestPosition: CardPosition
        
        if cardTopEdgeLocation <= CardPosition.middle.rawValue {
            positionAbove = .top
            positionBelow = .middle
        } else {
            positionAbove = .middle
            positionBelow = .middle
        }
        
        if (cardTopEdgeLocation - positionAbove.rawValue) < (positionBelow.rawValue - cardTopEdgeLocation) {
            closestPosition = positionAbove
        } else {
            closestPosition = positionBelow
        }
        
        withAnimation(.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0)) {
            if verticalDirection > 0 {
                viewModel.slidingCardOffset = positionBelow.rawValue
                self.position = positionBelow
            } else if verticalDirection < 0 {
                viewModel.slidingCardOffset = positionAbove.rawValue
                self.position = positionAbove
            } else {
                viewModel.slidingCardOffset = closestPosition.rawValue
                self.position = closestPosition
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
                    .tint(.white)
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

struct TutorialView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    
    var body: some View {
        switch viewModel.tutorialStep {
        case 0:
            IntroTutorialView()
        case 1:
            PrivacyTutorialView()
        case 2:
            FuelTutorialView()
        case 3:
            LocationTutorialView()
        case 4:
            LocationSecondTutorialView()
        default:
            IntroTutorialView()
        }
    }
}

struct IntroTutorialView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    
    var body: some View {
        VStack {
            Text("¡Hola!")
                .font(.title)
                .fontWeight(.heavy)
                .fontDesign(.rounded)
                .multilineTextAlignment(.leading)
                .padding(.top, 30)
            
            Spacer()
            Text("Soy DondeGas y me dedico a buscar (y encontrar 😎) los mejores precios para repostar. ¿Quieres ahorrar en cada visita a la gasolinera?")
                .font(.callout)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 30)
                .padding(.top, 16)
            Spacer()
            
            Button(action: {
                withAnimation {
                    viewModel.tutorialStep += 1
                }
            }){
                Text("¡Suena bien!")
                    .bold()
                    .tint(.white)
                    .padding()
            }
            .background(.blue)
            .cornerRadius(50, corners: .allCorners)
            .padding(.bottom, 30)
        }
        .frame(width: 300, height: !viewModel.wasTutorialShown && !viewModel.isLoading ? 300 : 0)
        .background(Color("TranslucidBackgroundColor"))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(!viewModel.wasTutorialShown && !viewModel.isLoading ? 1 : 0)
        .offset(y: (!viewModel.wasTutorialShown && !viewModel.isLoading ? -5 : 150) + viewModel.slidingCardOffset)
    }
}

struct PrivacyTutorialView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        VStack {
            Spacer()
            Text("Empecemos por revisar la política de privacidad de DondeGas. Tus datos nunca abandonan tu dispositivo y se usan solo para mostrarte resultados relevantes 🙂")
                .font(.callout)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 30)
                .padding(.top, 16)
            Spacer()
            
            Button(action: {
                showingPrivacyPolicy = true
            }) {
                Spacer()
                Text("Política de Privacidad")
                    .bold()
                    .tint(Color("TextColor"))
                    .padding()
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .frame(width: 240)
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            
            Button(action: {
                withAnimation {
                    viewModel.tutorialStep += 1
                }
            }){
                Spacer()
                Text("Acepto")
                    .bold()
                    .tint(.white)
                    .padding()
                Spacer()
            }
            .background(.blue)
            .cornerRadius(50, corners: .allCorners)
            .frame(width: 240)
            
            Spacer()
        }
        .frame(width: 300, height: !viewModel.wasTutorialShown && !viewModel.isLoading ? 300 : 0)
        .background(Color("TranslucidBackgroundColor"))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(!viewModel.wasTutorialShown && !viewModel.isLoading ? 1 : 0)
        .offset(y: (!viewModel.wasTutorialShown && !viewModel.isLoading ? -5 : 150) + viewModel.slidingCardOffset)
    }
}


struct FuelTutorialView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size:32))
                        .foregroundColor(viewModel.getFuelTypeColor(fuelType: viewModel.selectedFuelType))
                    (Text("Este es el ")
                    + Text("menú de combustible.")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(viewModel.getFuelTypeColor(fuelType: viewModel.selectedFuelType)))
                    Spacer()
                }
                .padding(.top, 25)
                
                Text("\n\nElige el tipo de combustible que usa tu vehículo y buscaré los mejores precios en estaciones cercanas.")
                    .font(.callout)
                    .padding(.horizontal, 30)
                    .multilineTextAlignment(.leading)
            }
            
            Button(action: {
                withAnimation {
                    viewModel.tutorialStep += 1
                }
            }){
                Text("¡Entendido!")
                    .bold()
                    .tint(.white)
                    .padding()
            }
            .background(.blue)
            .cornerRadius(50, corners: .allCorners)
            .padding()
        }
        .frame(width: 300, height: !viewModel.wasTutorialShown && !viewModel.isLoading ? 300 : 0)
        .background(Color("TranslucidBackgroundColor"))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(!viewModel.wasTutorialShown && !viewModel.isLoading ? 1 : 0)
        .offset(y: (!viewModel.wasTutorialShown && !viewModel.isLoading ? -5 : 150) + viewModel.slidingCardOffset)
    }
}

struct LocationTutorialView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Image(systemName: "location.fill")
                        .font(.system(size:32))
                        .foregroundColor(viewModel.getFuelTypeColor(fuelType: viewModel.selectedFuelType))
                    (Text("Este es el ")
                    + Text("menú de localización.")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(viewModel.getFuelTypeColor(fuelType: viewModel.selectedFuelType)))
                    Spacer()
                }
                .padding(.top, 25)
                Spacer()
                Text("Puedo buscar estaciones en tu ubicación actual o explorar gasolineras en otras ubicaciones.")
                    .font(.callout)
                    .padding(.horizontal, 30)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            Button(action: {
                withAnimation {
                    viewModel.tutorialStep += 1
                }
            }){
                Text("¿Y qué más?")
                    .bold()
                    .tint(Color("TextColor"))
                    .padding()
            }
            .background(.blue)
            .cornerRadius(50, corners: .allCorners)
            .padding()
        }
        .frame(width: 300, height: !viewModel.wasTutorialShown && !viewModel.isLoading ? 300 : 0)
        .background(Color("TranslucidBackgroundColor"))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(!viewModel.wasTutorialShown && !viewModel.isLoading ? 1 : 0)
        .offset(y: (!viewModel.wasTutorialShown && !viewModel.isLoading ? -5 : 150) + viewModel.slidingCardOffset)
    }
}

struct LocationSecondTutorialView: View {
    @EnvironmentObject var viewModel: DondeGasViewModel
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Image(systemName: "location.fill")
                        .font(.system(size:32))
                        .foregroundColor(viewModel.getFuelTypeColor(fuelType: viewModel.selectedFuelType))
                    (Text("Este es el ")
                    + Text("menú de localización.")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(viewModel.getFuelTypeColor(fuelType: viewModel.selectedFuelType)))
                    Spacer()
                }
                .padding(.top, 25)
                Spacer()
                Text("También puedes personalizar la distancia máxima a la que buscaré estaciones de servicio.")
                    .font(.callout)
                    .padding(.horizontal, 30)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            Button(action: {
                viewModel.setTutorialAsCompleted()
            }){
                Text("¡Genial, todo listo!")
                    .bold()
                    .tint(Color("TextColor"))
                    .padding()
            }
            .background(.blue)
            .cornerRadius(50, corners: .allCorners)
            .padding()
        }
        .frame(width: 300, height: !viewModel.wasTutorialShown && !viewModel.isLoading ? 300 : 0)
        .background(Color("TranslucidBackgroundColor"))
        .cornerRadius(10)
        .shadow(radius: 5)
        .opacity(!viewModel.wasTutorialShown && !viewModel.isLoading ? 1 : 0)
        .offset(y: (!viewModel.wasTutorialShown && !viewModel.isLoading ? -5 : 150) + viewModel.slidingCardOffset)
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.colorScheme) var colorScheme
    let policy = PrivacyPolicy()

    var body: some View {
        VStack {
            Text("Política de Privacidad")
                .font(.system(size: 24, weight: .heavy))
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)
                .padding()
 
            WebView(htmlContent: colorScheme == .dark ? policy.darkHtmlText : policy.clearHtmlText)
                .padding()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct WebView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}






