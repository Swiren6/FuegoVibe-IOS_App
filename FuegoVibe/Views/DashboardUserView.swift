//
//  DashboardUserView.swift
//  FuegoVibe
//
//  REDESIGN: Dark theme throughout, vibrant category-colored event cards,
//  modern search bar, pill category filters, redesigned profile tab.
//

import SwiftUI
import FirebaseAuth

// MARK: - Dashboard Root

struct DashboardUserView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var quoteVM: QuoteViewModel

    @State private var selectedTab = 0
    @State private var showQuoteSplash = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeTabContent()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)

                ProfileTabContent()
                    .tabItem { Label("Profile", systemImage: "person.fill") }
                    .tag(1)
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
                    withAnimation(.easeIn(duration: 0.3)) {
                        showQuoteSplash = true
                    }
                }
            }
        }
    }
}

// MARK: - Home Tab

struct HomeTabContent: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var quoteVM: QuoteViewModel

    @State private var searchText = ""
    @State private var selectedCategory: EventCategory?

    var firstName: String {
        authVM.currentAppUser?.email.components(separatedBy: "@").first?.capitalized ?? "there"
    }

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
                    // ── Custom header ──
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hey, \(firstName) 👋")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(FV.Colors.primary)
                            Text("What's happening near you?")
                                .font(.system(size: 14))
                                .foregroundColor(FV.Colors.secondary)
                        }

                        Spacer()

                        Button {
                            authVM.signOut()
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(FV.Colors.secondary)
                                .padding(10)
                                .background(FV.Colors.surface)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                    // ── Search ──
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(searchText.isEmpty ? FV.Colors.tertiary : FV.Colors.fire)
                            .font(.system(size: 16))

                        TextField("Search events...", text: $searchText)
                            .foregroundColor(FV.Colors.primary)
                            .tint(FV.Colors.fire)
                            .font(.system(size: 15))

                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(FV.Colors.tertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(FV.Colors.surface)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(FV.Colors.border, lineWidth: 1))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // ── Category filters ──
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryChip(title: "All", icon: "square.grid.2x2", color: FV.Colors.fire, isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(EventCategory.allCases, id: \.self) { cat in
                                CategoryChip(
                                    title: cat.rawValue,
                                    icon: cat.icon,
                                    color: FV.Category.color(for: cat),
                                    isSelected: selectedCategory == cat
                                ) {
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
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: FV.Colors.fire))
                        Spacer()
                    } else if filteredEvents.isEmpty {
                        EmptyEventsView()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredEvents) { event in
                                    NavigationLink(destination: EventDetailView(event: event)) {
                                        EventCardView(event: event)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                eventVM.startListening()
                Task { await quoteVM.loadQuoteWithCache() }
            }
            .onDisappear {
                eventVM.stopListening()
            }
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : FV.Colors.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isSelected
                    ? color
                    : FV.Colors.surface
            )
            .cornerRadius(20)
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : FV.Colors.border, lineWidth: 1)
            )
            .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Event Card

struct EventCardView: View {
    let event: Event

    private var categoryColor: Color { FV.Category.color(for: event.category) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Colorful banner ──
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [categoryColor, categoryColor.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)

                // Pattern overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                HStack {
                    // Category badge
                    HStack(spacing: 5) {
                        Image(systemName: event.category.icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(event.category.rawValue)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)

                    Spacer()

                    // Price badge
                    if event.isFree {
                        Text("FREE")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(categoryColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white)
                            .cornerRadius(10)
                    } else if let price = event.price {
                        Text("DT \(Int(price))")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(categoryColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(12)
            }
            .cornerRadius(16, corners: [.topLeft, .topRight])

            // ── Card body ──
            VStack(alignment: .leading, spacing: 10) {
                Text(event.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(FV.Colors.primary)
                    .lineLimit(2)

                HStack(spacing: 16) {
                    Label(event.location, systemImage: "location.fill")
                        .lineLimit(1)

                    Label(event.formattedDate, systemImage: "calendar")
                        .lineLimit(1)
                }
                .font(.system(size: 13))
                .foregroundColor(FV.Colors.secondary)

                // Participants bar
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(categoryColor)

                    if let max = event.maxParticipants, max > 0 {
                        let progress = Double(event.currentParticipants) / Double(max)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(FV.Colors.surfaceHigh)
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(categoryColor)
                                    .frame(width: geo.size.width * progress, height: 4)
                            }
                        }
                        .frame(height: 4)

                        Text("\(event.currentParticipants)/\(max)")
                            .font(.system(size: 12))
                            .foregroundColor(FV.Colors.secondary)
                    } else {
                        Text("\(event.currentParticipants) going")
                            .font(.system(size: 12))
                            .foregroundColor(FV.Colors.secondary)
                    }
                }
            }
            .padding(16)
            .background(FV.Colors.surface)
            .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Event Detail View

struct EventDetailView: View {
    let event: Event
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @State private var showTicketSite = false

    private var categoryColor: Color { FV.Category.color(for: event.category) }

    // Detect the source platform from sourceURL
    private var sourcePlatform: SourcePlatform? {
        guard let url = event.sourceURL else { return nil }
        if url.contains("teskerti.tn")   { return .teskerti }
        if url.contains("monticket.tn")  { return .monticket }
        return .other(url)
    }

    var body: some View {
        ZStack {
            FV.Colors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Hero Image or Gradient ──
                    ZStack(alignment: .bottom) {
                        if let imageURL = event.imageURL, let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 240)
                                        .clipped()
                                        .overlay(
                                            LinearGradient(
                                                colors: [.clear, FV.Colors.background.opacity(0.9)],
                                                startPoint: .center,
                                                endPoint: .bottom
                                            )
                                        )
                                case .empty:  // loading state
                                    ZStack {
                                        LinearGradient(
                                            colors: [categoryColor, categoryColor.opacity(0.4), FV.Colors.background],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                    .frame(height: 240)
                                default:
                                    heroBanner
                                }
                            }
                        } else {
                            heroBanner
                        }

                        // Category + source badge row
                        HStack {
                            // Category pill
                            HStack(spacing: 6) {
                                Image(systemName: event.category.icon)
                                    .font(.system(size: 12))
                                Text(event.category.rawValue)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)

                            Spacer()

                            // Source platform badge
                            if let platform = sourcePlatform {
                                HStack(spacing: 5) {
                                    Image(systemName: "ticket.fill")
                                        .font(.system(size: 11))
                                    Text(platform.name)
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(platform.color.opacity(0.85))
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }

                    VStack(alignment: .leading, spacing: 18) {

                        // ── Title + Price ──
                        HStack(alignment: .top, spacing: 12) {
                            Text(event.title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(FV.Colors.primary)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                if event.isFree {
                                    Text("GRATUIT")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.green.opacity(0.15))
                                        .cornerRadius(8)
                                } else if let price = event.price {
                                    Text("À partir de")
                                        .font(.system(size: 10))
                                        .foregroundColor(FV.Colors.tertiary)
                                    Text("DT \(Int(price))")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(FV.fireGradient)
                                }
                            }
                        }

                        // ── Info block ──
                        VStack(spacing: 0) {
                            DetailInfoRow(icon: "mappin.and.ellipse", color: categoryColor, text: event.location)
                            Divider().background(FV.Colors.border).padding(.leading, 34)
                            DetailInfoRow(icon: "calendar", color: categoryColor, text: event.formattedDate)
                            Divider().background(FV.Colors.border).padding(.leading, 34)
                            DetailInfoRow(
                                icon: "person.2.fill",
                                color: categoryColor,
                                text: event.maxParticipants != nil
                                    ? "\(event.currentParticipants) / \(event.maxParticipants!) participants"
                                    : "\(event.currentParticipants) participants"
                            )
                        }
                        .padding(16)
                        .background(FV.Colors.surface)
                        .cornerRadius(16)

                        // ── Description ──
                        VStack(alignment: .leading, spacing: 10) {
                            Text("À propos")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(FV.Colors.primary)

                            Text(event.description
                                    .replacingOccurrences(of: "🔗.*", with: "", options: .regularExpression)
                                    .trimmingCharacters(in: .whitespacesAndNewlines))
                                .font(.system(size: 14))
                                .foregroundColor(FV.Colors.secondary)
                                .lineSpacing(5)
                        }
                        .padding(16)
                        .background(FV.Colors.surface)
                        .cornerRadius(16)

                        // ── BUY TICKET BUTTON (Teskerti / MonTicket) ──
                        if let platform = sourcePlatform,
                           let urlString = event.sourceURL,
                           let url = URL(string: urlString) {

                            VStack(spacing: 10) {
                                // Main buy button
                                Link(destination: url) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "ticket.fill")
                                            .font(.system(size: 16))
                                        Text("Acheter sur \(platform.name)")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .frame(height: 58)
                                    .background(platform.gradient)
                                    .cornerRadius(16)
                                    .shadow(color: platform.color.opacity(0.4), radius: 12, x: 0, y: 6)
                                }

                                // Disclaimer
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 11))
                                    Text("Tu seras redirigé vers \(platform.domain) pour finaliser l'achat.")
                                        .font(.system(size: 11))
                                }
                                .foregroundColor(FV.Colors.tertiary)
                                .multilineTextAlignment(.center)
                            }
                            .padding(16)
                            .background(FV.Colors.surface)
                            .cornerRadius(16)
                        }

                        // ── Join / Leave (FuegoVibe events only) ──
                        if event.sourceURL == nil, let userId = authVM.user?.uid {
                            if event.isUserParticipating(userId: userId) {
                                Button {
                                    Task { await eventVM.leaveEvent(event, userId: userId) }
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                        Text("Se désinscrire").fontWeight(.semibold)
                                    }
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.red.opacity(0.12))
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.25), lineWidth: 1))
                                }
                                .disabled(eventVM.isJoining)
                            } else {
                                Button {
                                    Task { await eventVM.joinEvent(event, userId: userId) }
                                } label: {
                                    HStack {
                                        if eventVM.isJoining {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Rejoindre l'événement").fontWeight(.semibold)
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(LinearGradient(
                                        colors: [categoryColor, categoryColor.opacity(0.7)],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .cornerRadius(16)
                                    .shadow(color: categoryColor.opacity(0.35), radius: 12, x: 0, y: 6)
                                }
                                .disabled(eventVM.isJoining || event.isFull)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 30)
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(event.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(FV.Colors.primary)
                    .lineLimit(1)
            }
        }
    }

    // Gradient hero fallback (when no image)
    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [categoryColor, categoryColor.opacity(0.4), FV.Colors.background],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 240)

            Image(systemName: event.category.icon)
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.white.opacity(0.15))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Source Platform

enum SourcePlatform {
    case teskerti
    case monticket
    case other(String)

    var name: String {
        switch self {
        case .teskerti:    return "Teskerti.tn"
        case .monticket:   return "MonTicket.tn"
        case .other:       return "Site externe"
        }
    }

    var domain: String {
        switch self {
        case .teskerti:    return "teskerti.tn"
        case .monticket:   return "monticket.tn"
        case .other(let u): return URL(string: u)?.host ?? "site externe"
        }
    }

    var color: Color {
        switch self {
        case .teskerti:    return Color(red: 0.85, green: 0.22, blue: 0.25)  // Teskerti red
        case .monticket:   return Color(red: 0.13, green: 0.55, blue: 0.89)  // MonTicket blue
        case .other:       return FV.Colors.fire
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .teskerti:
            return LinearGradient(
                colors: [Color(red: 0.85, green: 0.22, blue: 0.25),
                         Color(red: 0.65, green: 0.10, blue: 0.15)],
                startPoint: .leading, endPoint: .trailing
            )
        case .monticket:
            return LinearGradient(
                colors: [Color(red: 0.13, green: 0.55, blue: 0.89),
                         Color(red: 0.08, green: 0.35, blue: 0.72)],
                startPoint: .leading, endPoint: .trailing
            )
        case .other:
            return FV.fireGradient
        }
    }
}

struct DetailInfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(FV.Colors.secondary)
            Spacer()
        }
    }
}

// MARK: - Empty State

struct EmptyEventsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 52))
                .foregroundColor(FV.Colors.tertiary)

            Text("No events found")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(FV.Colors.secondary)

            Text("Check back later for new events")
                .font(.system(size: 14))
                .foregroundColor(FV.Colors.tertiary)
        }
        .frame(maxHeight: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Profile Tab

struct ProfileTabContent: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel

    var body: some View {
        NavigationView {
            ZStack {
                FV.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Avatar + info ──
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(FV.fireGradient)
                                    .frame(width: 88, height: 88)
                                    .shadow(color: FV.Colors.fire.opacity(0.35), radius: 16)

                                Text(
                                    String(
                                        (authVM.currentAppUser?.email.prefix(1) ?? "U")
                                    ).uppercased()
                                )
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            }
                            .padding(.top, 30)

                            VStack(spacing: 6) {
                                Text(authVM.currentAppUser?.email ?? "")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(FV.Colors.primary)

                                if let date = authVM.currentAppUser?.createdAt {
                                    Text("Member since \(date.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.system(size: 13))
                                        .foregroundColor(FV.Colors.tertiary)
                                }
                            }
                        }

                        // ── Stats row ──
                        HStack(spacing: 1) {
                            ProfileStatItem(value: "\(eventVM.joinedEvents.count)", label: "Joined")
                            Divider()
                                .background(FV.Colors.border)
                                .frame(height: 40)
                            ProfileStatItem(value: "\(eventVM.events.count)", label: "Available")
                        }
                        .background(FV.Colors.surface)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)

                        // ── Actions ──
                        VStack(spacing: 2) {
                            Text("My Activity")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(FV.Colors.tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)

                            NavigationLink(destination: JoinedEventsView()) {
                                ProfileActionRow(
                                    icon: "ticket.fill",
                                    label: "Events Joined",
                                    value: "\(eventVM.joinedEvents.count)",
                                    color: FV.Colors.fire
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 20)
                        }

                        // ── Sign out ──
                        Button {
                            authVM.signOut()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out").fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if let userId = authVM.user?.uid {
                eventVM.startMyEventsListener(userId: userId)
                eventVM.startJoinedEventsListener(userId: userId)
            }
        }
        .onDisappear {
            eventVM.stopMyEventsListener()
            eventVM.stopJoinedEventsListener()
        }
    }
}

struct ProfileStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(FV.fireGradient)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(FV.Colors.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct ProfileActionRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15))
                .cornerRadius(10)

            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(FV.Colors.primary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(FV.Colors.secondary)

            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(FV.Colors.tertiary)
        }
        .padding(16)
        .background(FV.Colors.surface)
        .cornerRadius(14)
    }
}

// MARK: - Joined Events View

struct JoinedEventsView: View {
    @EnvironmentObject var eventVM: EventViewModel

    var body: some View {
        ZStack {
            FV.Colors.background.ignoresSafeArea()

            if eventVM.joinedEvents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "ticket")
                        .font(.system(size: 48))
                        .foregroundColor(FV.Colors.tertiary)
                    Text("No joined events yet")
                        .foregroundColor(FV.Colors.secondary)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        ForEach(eventVM.joinedEvents) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventCardView(event: event)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Joined Events")
        .preferredColorScheme(.dark)
    }
}

// MARK: - Corner Radius Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    DashboardUserView()
        .environmentObject(AuthViewModel())
        .environmentObject(EventViewModel())
        .environmentObject(QuoteViewModel())
}
