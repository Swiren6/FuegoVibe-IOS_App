//
//  DashboardAdminView.swift
//  FuegoVibe
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct DashboardAdminView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var quoteVM: QuoteViewModel

    @State private var selectedTab = 0
    @State private var showQuoteSplash = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                AdminHomeTab()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)

                AdminStatsTab()
                    .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                    .tag(1)

                CreateEventTab()
                    .tabItem { Label("Create", systemImage: "plus.circle.fill") }
                    .tag(2)

                UsersManagementTab()
                    .tabItem { Label("Users", systemImage: "person.2.fill") }
                    .tag(3)

                AdminSettingsTab()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(4)
            }
            .accentColor(FV.Colors.fire)

            if showQuoteSplash, let quote = quoteVM.quoteOfTheDay {
                QuoteSplashView(quote: quote, isPresented: $showQuoteSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .darkAppearance()
        .preferredColorScheme(.dark)
        .onAppear {
            Task {
                await quoteVM.loadQuoteWithCache()
                if quoteVM.quoteOfTheDay == nil {
                    quoteVM.quoteOfTheDay = Quote.randomFallback
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { showQuoteSplash = true }
                }
            }
        }
    }
}

// MARK: - Admin Home Tab

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
        if !searchText.isEmpty { events = eventVM.searchEvents(query: searchText) }
        if let cat = selectedCategory { events = events.filter { $0.category == cat } }
        return events
    }

    var body: some View {
        NavigationView {
            ZStack {
                FV.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Admin header ──
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(FV.Colors.fire)
                                Text("ADMIN")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(FV.Colors.fire)
                            }

                            Text(authVM.currentAppUser?.email.components(separatedBy: "@").first?.capitalized ?? "Admin")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(FV.Colors.primary)
                        }

                        Spacer()

                        Button {
                            authVM.signOut()
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 15))
                                .foregroundColor(.red)
                                .padding(10)
                                .background(Color.red.opacity(0.12))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .background(FV.Colors.background)

                    // Gradient separator line
                    Rectangle()
                        .fill(FV.fireGradient)
                        .frame(height: 1)
                        .opacity(0.5)

                    // ── Search ──
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(searchText.isEmpty ? FV.Colors.tertiary : FV.Colors.fire)
                            .font(.system(size: 15))

                        TextField("Search events...", text: $searchText)
                            .foregroundColor(FV.Colors.primary)
                            .tint(FV.Colors.fire)

                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(FV.Colors.tertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(FV.Colors.surface)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(FV.Colors.border, lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                    // ── Category filters ──
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryChip(title: "All", icon: "square.grid.2x2", color: FV.Colors.fire,
                                         isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(EventCategory.allCases, id: \.self) { cat in
                                CategoryChip(title: cat.rawValue, icon: cat.icon,
                                             color: FV.Category.color(for: cat),
                                             isSelected: selectedCategory == cat) {
                                    selectedCategory = cat
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 12)

                    // ── Events list ──
                    if eventVM.isFetchingEvents {
                        Spacer()
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: FV.Colors.fire))
                        Spacer()
                    } else if filteredEvents.isEmpty {
                        EmptyEventsView()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 14) {
                                ForEach(filteredEvents) { event in
                                    AdminEventCard(event: event, onDelete: {
                                        eventToDelete = event
                                        showDeleteAlert = true
                                    })
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Delete Event", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let event = eventToDelete, let id = event.id {
                        Task { await eventVM.deleteEvent(id) }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this event?")
            }
            .onAppear {
                eventVM.startListening()
            }
            .onDisappear {
                eventVM.stopListening()
            }
        }
    }
}

// MARK: - Admin Event Card

struct AdminEventCard: View {
    let event: Event
    let onDelete: () -> Void

    private var catColor: Color { FV.Category.color(for: event.category) }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            Rectangle()
                .fill(catColor)
                .frame(width: 4)
                .cornerRadius(2, corners: [.topLeft, .bottomLeft])

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(FV.Colors.primary)

                        Text(event.organizerEmail)
                            .font(.caption)
                            .foregroundColor(FV.Colors.tertiary)
                    }
                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: event.category.icon).font(.caption2)
                        Text(event.category.rawValue).font(.caption)
                    }
                    .foregroundColor(catColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(catColor.opacity(0.15))
                    .cornerRadius(8)
                }

                HStack(spacing: 16) {
                    Label(event.location, systemImage: "location.fill")
                    Label(event.formattedDate, systemImage: "calendar")
                }
                .font(.system(size: 12))
                .foregroundColor(FV.Colors.secondary)
                .lineLimit(1)

                HStack {
                    if event.isFree {
                        Text("FREE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(6)
                    } else if let price = event.price {
                        Text("DT \(Int(price))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(catColor)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(catColor.opacity(0.15))
                            .cornerRadius(6)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill").font(.caption2)
                        Text(event.maxParticipants != nil
                            ? "\(event.currentParticipants)/\(event.maxParticipants!)"
                            : "\(event.currentParticipants)")
                            .font(.caption)
                    }
                    .foregroundColor(FV.Colors.secondary)

                    Spacer()

                    HStack(spacing: 10) {
                        NavigationLink(destination: EditEventView(event: event)) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(FV.Category.technology)
                        }
                        Button(action: onDelete) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                }
            }
            .padding(14)
        }
        .background(FV.Colors.surface)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Stats Tab

struct AdminStatsTab: View {
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var userVM: UserViewModel

    var body: some View {
        NavigationView {
            ZStack {
                FV.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            DarkStatCard(icon: "calendar.badge.plus", title: "Total Events",
                                         value: "\(eventVM.events.count)", color: FV.Colors.fire)
                            DarkStatCard(icon: "person.3.fill", title: "Total Users",
                                         value: "\(userVM.totalUsers)", color: FV.Category.business)
                            DarkStatCard(icon: "crown.fill", title: "Admins",
                                         value: "\(userVM.totalAdmins)", color: FV.Category.food)
                            DarkStatCard(icon: "calendar", title: "Upcoming",
                                         value: "\(eventVM.getUpcomingEvents().count)", color: FV.Category.sports)
                        }
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Users")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(FV.Colors.primary)
                                .padding(.horizontal, 20)

                            ForEach(userVM.recentUsers) { user in
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(user.isAdmin ? AnyShapeStyle(FV.fireGradient) : AnyShapeStyle(FV.Colors.surfaceHigh))
                                        .frame(width: 42, height: 42)
                                        .overlay(
                                            Text(String(user.email.prefix(1)).uppercased())
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(user.isAdmin ? .white : FV.Colors.secondary)
                                        )

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(user.email)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(FV.Colors.primary)
                                        Text(user.createdAt.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundColor(FV.Colors.tertiary)
                                    }

                                    Spacer()

                                    if user.isAdmin {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(FV.Colors.fire)
                                    }
                                }
                                .padding(14)
                                .background(FV.Colors.surface)
                                .cornerRadius(14)
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                Task { await userVM.fetchAllUsers() }
            }
        }
    }
}

struct DarkStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .padding(10)
                .background(color.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(FV.Colors.primary)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(FV.Colors.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(FV.Colors.surface)
        .cornerRadius(16)
    }
}

// MARK: - Create Event Tab

struct CreateEventTab: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel

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
            ZStack {
                FV.Colors.background.ignoresSafeArea()

                Form {
                    Section("Event Details") {
                        TextField("Title", text: $title)
                        TextField("Description", text: $description, axis: .vertical).lineLimit(3...6)
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(EventCategory.allCases, id: \.self) { cat in
                                Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                            }
                        }
                    }
                    Section("Date & Time") {
                        DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    Section("Location") {
                        TextField("Location", text: $location)
                    }
                    Section("Pricing") {
                        Toggle("Free Event", isOn: $isFree)
                        if !isFree {
                            TextField("Price (DT)", text: $price).keyboardType(.decimalPad)
                        }
                    }
                    Section("Capacity") {
                        TextField("Max Participants (optional)", text: $maxParticipants).keyboardType(.numberPad)
                    }
                    Section("Visibility") {
                        Toggle("Public Event", isOn: $isPublic)
                    }
                    Section {
                        Button(action: createEvent) {
                            HStack {
                                Spacer()
                                if eventVM.isCreating {
                                    ProgressView()
                                } else {
                                    Text("Create Event").fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .disabled(!isFormValid || eventVM.isCreating)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") { clearForm() }
            } message: { Text("Event created successfully!") }
        }
    }

    var isFormValid: Bool { !title.isEmpty && !description.isEmpty && !location.isEmpty }

    func createEvent() {
        guard let user = authVM.user else { return }
        let event = Event(title: title, description: description, category: selectedCategory,
                          startDate: startDate, endDate: endDate, location: location,
                          organizerId: user.uid, organizerEmail: user.email ?? "",
                          maxParticipants: Int(maxParticipants), isFree: isFree,
                          price: isFree ? nil : Double(price), isPublic: isPublic)
        Task {
            let success = await eventVM.createEvent(event)
            if success { showSuccessAlert = true }
        }
    }

    func clearForm() {
        title = ""; description = ""; location = ""; price = ""; maxParticipants = ""
        startDate = Date(); endDate = Date().addingTimeInterval(3600); isFree = true; isPublic = true
    }
}

// MARK: - Edit Event

struct EditEventView: View {
    let event: Event
    @EnvironmentObject var eventVM: EventViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isFree = true
    @State private var price = ""
    @State private var isPublic = true

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $title)
                TextField("Description", text: $description, axis: .vertical).lineLimit(3...6)
                TextField("Location", text: $location)
            }
            Section("Date & Time") {
                DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
            }
            Section("Pricing") {
                Toggle("Free Event", isOn: $isFree)
                if !isFree { TextField("Price (DT)", text: $price).keyboardType(.decimalPad) }
            }
            Section("Visibility") { Toggle("Public Event", isOn: $isPublic) }
            Section {
                Button("Save Changes") {
                    var e = event
                    e.title = title; e.description = description; e.location = location
                    e.startDate = startDate; e.endDate = endDate
                    e.isFree = isFree; e.price = isFree ? nil : Double(price); e.isPublic = isPublic
                    Task {
                        let ok = await eventVM.updateEvent(e)
                        if ok { dismiss() }
                    }
                }
            }
        }
        .navigationTitle("Edit Event")
        .onAppear {
            title = event.title; description = event.description; location = event.location
            startDate = event.startDate; endDate = event.endDate
            isFree = event.isFree; price = event.price.map { String($0) } ?? ""; isPublic = event.isPublic
        }
    }
}

// MARK: - Users Management Tab

struct UsersManagementTab: View {
    @EnvironmentObject var userVM: UserViewModel

    var body: some View {
        NavigationView {
            ZStack {
                FV.Colors.background.ignoresSafeArea()
                userListContent
            }
            .navigationTitle("Users")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await userVM.fetchAllUsers() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear { Task { await userVM.fetchAllUsers() } }
        }
    }

    // Extracted to help the compiler type-check
    @ViewBuilder
    private var userListContent: some View {
        if userVM.isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FV.Colors.fire))
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(userVM.users) { user in
                        UserListRow(user: user)
                    }
                }
                .padding(20)
            }
        }
    }
}

// Extracted row — fixes "unable to type-check in reasonable time" error
struct UserListRow: View {
    let user: AppUser

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            let fill: AnyShapeStyle = user.isAdmin
                ? AnyShapeStyle(FV.fireGradient)
                : AnyShapeStyle(FV.Colors.surfaceHigh)

            Circle()
                .fill(fill)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(user.email.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(user.isAdmin ? .white : FV.Colors.secondary)
                )

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(user.email)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FV.Colors.primary)
                Text("Joined: \(user.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(FV.Colors.tertiary)
            }

            Spacer()

            // Admin badge
            if user.isAdmin {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill").font(.caption2)
                    Text("Admin").font(.caption)
                }
                .foregroundColor(FV.Colors.fire)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(FV.Colors.fire.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding(14)
        .background(FV.Colors.surface)
        .cornerRadius(14)
    }
}

// MARK: - Settings Tab

struct AdminSettingsTab: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationView {
            ZStack {
                FV.Colors.background.ignoresSafeArea()

                List {
                    Section("Account") {
                        if let user = authVM.currentAppUser {
                            HStack {
                                Text("Email").foregroundColor(FV.Colors.secondary)
                                Spacer()
                                Text(user.email).foregroundColor(FV.Colors.tertiary).font(.system(size: 14))
                            }
                            HStack {
                                Text("Role").foregroundColor(FV.Colors.secondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill").font(.caption)
                                    Text("Admin").font(.system(size: 14))
                                }
                                .foregroundColor(FV.Colors.fire)
                            }
                        }
                    }
                    Section("App Info") {
                        HStack {
                            Text("Version").foregroundColor(FV.Colors.secondary)
                            Spacer()
                            Text("1.0.0").foregroundColor(FV.Colors.tertiary)
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
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    DashboardAdminView()
        .environmentObject(AuthViewModel())
        .environmentObject(EventViewModel())
        .environmentObject(QuoteViewModel())
        .environmentObject(UserViewModel())
}
