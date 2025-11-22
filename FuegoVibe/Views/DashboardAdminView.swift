//
//  DashboardAdminView.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct DashboardAdminView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 🏠 Accueil - Liste des événements
            AdminHomeTab()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // 📊 Dashboard Stats
            AdminStatsTab()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            // ➕ Créer événement
            CreateEventTab()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            // 👥 Utilisateurs
            UsersManagementTab()
                .tabItem {
                    Label("Users", systemImage: "person.2.fill")
                }
                .tag(3)
            
            // ⚙️ Settings
            AdminSettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(.purple)
    }
}

// MARK: - Home Tab (Liste des événements)
struct AdminHomeTab: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var quoteVM: QuoteViewModel
    
    @State private var searchText = ""
    @State private var selectedCategory: EventCategory?
    @State private var showDeleteAlert = false
    @State private var eventToDelete: Event?
    
    var filteredEvents: [Event] {
        var events = eventVM.events
        
        if !searchText.isEmpty {
            events = eventVM.searchEvents(query: searchText)
        }
        
        if let category = selectedCategory {
            events = events.filter { $0.category == category }
        }
        
        return events
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Admin
                AdminHeaderBanner()
                
                // Barre de recherche
                SearchBar(text: $searchText)
                    .padding()
                
                // Citation du jour (version compacte pour admin)
                if let quote = quoteVM.quoteOfTheDay {
                    QuoteCardCompactView(quote: quote)
                        .padding(.horizontal)
                }
                
                // Filtres catégories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryFilterButton(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            icon: "square.grid.2x2"
                        ) {
                            selectedCategory = nil
                        }
                        
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            CategoryFilterButton(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                icon: category.icon
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                // Liste des événements
                if eventVM.isLoading {
                    ProgressView("Loading events...")
                        .frame(maxHeight: .infinity)
                } else if filteredEvents.isEmpty {
                    EmptyEventsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredEvents) { event in
                                AdminEventCard(
                                    event: event,
                                    onDelete: {
                                        eventToDelete = event
                                        showDeleteAlert = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Events Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await eventVM.fetchAllEvents()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert("Delete Event", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let event = eventToDelete, let eventId = event.id {
                        Task {
                            await eventVM.deleteEvent(eventId)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this event?")
            }
            .onAppear {
                // ✅ Listener temps réel - mise à jour automatique
                eventVM.startListening()
                
                // ✅ Charger la citation du jour
                Task {
                    await quoteVM.loadQuoteWithCache()
                }
            }
            .onDisappear {
                // Arrêter le listener quand on quitte
                eventVM.stopListening()
            }
        }
    }
}

// MARK: - Admin Header Banner
struct AdminHeaderBanner: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Admin Panel")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(authVM.currentAppUser?.email.components(separatedBy: "@").first ?? "Admin")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.title3)
                Text("ADMIN")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple, Color.pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Admin Event Card
struct AdminEventCard: View {
    let event: Event
    let onDelete: () -> Void
    @EnvironmentObject var eventVM: EventViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text(event.organizerEmail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Badge catégorie
                HStack(spacing: 4) {
                    Image(systemName: event.category.icon)
                        .font(.caption2)
                    Text(event.category.rawValue)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(getCategoryColor(event.category).opacity(0.2))
                .foregroundColor(getCategoryColor(event.category))
                .cornerRadius(8)
            }
            
            HStack(spacing: 16) {
                // Localisation
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(event.location)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                // Date
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(event.formattedDate)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            HStack {
                // Prix
                if event.isFree {
                    Text("FREE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                } else if let price = event.price {
                    Text("$\(Int(price))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                // Participants
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    if let max = event.maxParticipants {
                        Text("\(event.currentParticipants)/\(max)")
                            .font(.caption)
                    } else {
                        Text("\(event.currentParticipants)")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Actions admin
                HStack(spacing: 12) {
                    NavigationLink(destination: EditEventView(event: event)) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    func getCategoryColor(_ category: EventCategory) -> Color {
        switch category {
        case .music: return .purple
        case .sports: return .green
        case .arts: return .pink
        case .food: return .orange
        case .business: return .blue
        case .technology: return .indigo
        case .other: return .gray
        }
    }
}

// MARK: - Stats Tab
struct AdminStatsTab: View {
    @EnvironmentObject var eventVM: EventViewModel
    @State private var totalUsers = 0
    @State private var totalAdmins = 0
    @State private var users: [AppUser] = []
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            icon: "calendar.badge.plus",
                            title: "Total Events",
                            value: "\(eventVM.events.count)",
                            color: .purple
                        )
                        
                        StatCard(
                            icon: "person.3.fill",
                            title: "Total Users",
                            value: "\(totalUsers)",
                            color: .blue
                        )
                        
                        StatCard(
                            icon: "crown.fill",
                            title: "Admins",
                            value: "\(totalAdmins)",
                            color: .orange
                        )
                        
                        StatCard(
                            icon: "calendar",
                            title: "Upcoming",
                            value: "\(eventVM.getUpcomingEvents().count)",
                            color: .green
                        )
                    }
                    .padding()
                    
                    // Recent Users
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Users")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(users.prefix(5)) { user in
                            HStack {
                                Circle()
                                    .fill(user.isAdmin ? Color.purple : Color.blue)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(String(user.email.prefix(1)).uppercased())
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.email)
                                        .font(.subheadline)
                                    Text(user.createdAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if user.isAdmin {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.purple)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                Task {
                    await loadStats()
                }
            }
        }
    }
    
    func loadStats() async {
        do {
            let snapshot = try await db.collection("users").getDocuments()
            
            let allUsers = snapshot.documents.compactMap { doc -> AppUser? in
                let data = doc.data()
                guard let uid = data["uid"] as? String,
                      let email = data["email"] as? String else { return nil }
                
                let roleString = data["role"] as? String ?? "user"
                let role = UserRole(rawValue: roleString) ?? .user
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                
                var user = AppUser(uid: uid, email: email, role: role, createdAt: createdAt)
                user.id = uid
                return user
            }
            
            totalUsers = allUsers.count
            totalAdmins = allUsers.filter { $0.isAdmin }.count
            users = allUsers.sorted { $0.createdAt > $1.createdAt }
            
        } catch {
            print("❌ Error loading stats: \(error)")
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Create Event Tab
struct CreateEventTab: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: EventCategory = .music
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isFree = true
    @State private var price = ""
    @State private var maxParticipants = ""
    @State private var isPublic = true
    
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(EventCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Date & Time") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Location") {
                    TextField("Location", text: $location)
                }
                
                Section("Pricing") {
                    Toggle("Free Event", isOn: $isFree)
                    
                    if !isFree {
                        TextField("Price (USD)", text: $price)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Capacity") {
                    TextField("Max Participants (optional)", text: $maxParticipants)
                        .keyboardType(.numberPad)
                }
                
                Section("Visibility") {
                    Toggle("Public Event", isOn: $isPublic)
                }
                
                Section {
                    Button(action: createEvent) {
                        HStack {
                            Spacer()
                            if eventVM.isLoading {
                                ProgressView()
                            } else {
                                Text("Create Event")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || eventVM.isLoading)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    clearForm()
                }
            } message: {
                Text("Event created successfully!")
            }
        }
    }
    
    var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && !location.isEmpty
    }
    
    func createEvent() {
        guard let user = authVM.user else { return }
        
        let event = Event(
            title: title,
            description: description,
            category: selectedCategory,
            startDate: startDate,
            endDate: endDate,
            location: location,
            organizerId: user.uid,
            organizerEmail: user.email ?? "",
            maxParticipants: Int(maxParticipants),
            isFree: isFree,
            price: isFree ? nil : Double(price),
            isPublic: isPublic
        )
        
        Task {
            let success = await eventVM.createEvent(event)
            if success {
                // Le listener mettra à jour automatiquement la liste
                showSuccessAlert = true
            }
        }
    }
    
    func clearForm() {
        title = ""
        description = ""
        location = ""
        price = ""
        maxParticipants = ""
        startDate = Date()
        endDate = Date().addingTimeInterval(3600)
        isFree = true
        isPublic = true
    }
}

// MARK: - Edit Event View
struct EditEventView: View {
    let event: Event
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    
    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)
                TextField("Description", text: $description)
                TextField("Location", text: $location)
            }
            
            Section {
                Button("Save Changes") {
                    var updatedEvent = event
                    updatedEvent.title = title
                    updatedEvent.description = description
                    updatedEvent.location = location
                    
                    Task {
                        let success = await eventVM.updateEvent(updatedEvent)
                        if success {
                            dismiss()
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Event")
        .onAppear {
            title = event.title
            description = event.description
            location = event.location
        }
    }
}

// MARK: - Users Management Tab
struct UsersManagementTab: View {
    @State private var users: [AppUser] = []
    @State private var isLoading = false
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            List(users) { user in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.email)
                            .font(.headline)
                        Text("Joined: \(user.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if user.isAdmin {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                            Text("Admin")
                        }
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Users")
            .onAppear {
                Task { await loadUsers() }
            }
        }
    }
    
    func loadUsers() async {
        isLoading = true
        
        do {
            let snapshot = try await db.collection("users").getDocuments()
            
            self.users = snapshot.documents.compactMap { doc -> AppUser? in
                let data = doc.data()
                guard let uid = data["uid"] as? String,
                      let email = data["email"] as? String else { return nil }
                
                let roleString = data["role"] as? String ?? "user"
                let role = UserRole(rawValue: roleString) ?? .user
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                
                var user = AppUser(uid: uid, email: email, role: role, createdAt: createdAt)
                user.id = uid
                return user
            }
        } catch {
            print("❌ Error loading users: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Admin Settings Tab
struct AdminSettingsTab: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    if let user = authVM.currentAppUser {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Role")
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                Text("Admin")
                            }
                            .foregroundColor(.purple)
                        }
                    }
                }
                
                Section("App Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        authVM.signOut()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    DashboardAdminView()
        .environmentObject(AuthViewModel())
        .environmentObject(EventViewModel())
}
