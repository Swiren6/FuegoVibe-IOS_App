//
//  DashboardUserView.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
//

import SwiftUI
import SwiftData
import FirebaseAuth

// MARK: - Dashboard Principal
struct DashboardUserView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var quoteVM: QuoteViewModel
    @Query private var items: [Item]
    
    @State private var selectedTab = 0
    @State private var showQuoteSplash = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {

                HomeTabContent()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                ProfileTabContent()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(1)
                
                
            }
            
            //  Afficher le splash de citation
            if showQuoteSplash, let quote = quoteVM.quoteOfTheDay {
                QuoteSplashView(quote: quote, isPresented: $showQuoteSplash)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            
            Task {
                // Charger la citation
                await quoteVM.loadQuoteWithCache()
                
                // Vérifier que la citation existe
                if quoteVM.quoteOfTheDay == nil {
                    print("⚠️ Quote nil, utilisation du fallback")
                    quoteVM.quoteOfTheDay = Quote.randomFallback
                }
                
                print("✅ Citation chargée: \(quoteVM.quoteOfTheDay?.quote ?? "nil")")
                
                //  AFFICHER LE SPLASH (sans vérification de date)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showQuoteSplash = true
                    }
                    print("✨ Splash affiché")
                }
            }
        }
    }
    
    
}

// MARK: - Home Tab (Liste des événements)
struct HomeTabContent: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @EnvironmentObject var quoteVM: QuoteViewModel
    
    @State private var searchText = ""
    @State private var selectedCategory: EventCategory?
    
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
                SearchBar(text: $searchText)
                    .padding()
                
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
                
                if eventVM.isLoading {
                    ProgressView("Loading events...")
                        .frame(maxHeight: .infinity)
                } else if filteredEvents.isEmpty {
                    EmptyEventsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredEvents) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventCardView(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Welcome back, \(authVM.currentAppUser?.email.components(separatedBy: "@").first ?? "User")")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        authVM.signOut()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .onAppear {
                eventVM.startListening()
                Task {
                    await quoteVM.loadQuoteWithCache()
                }
            }
            .onDisappear {
                eventVM.stopListening()
            }
        }
    }
}

// MARK: - Composants UI

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search events...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct EventCardView: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [getCategoryColor(event.category), getCategoryColor(event.category).opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 150)
                    .cornerRadius(12)
                
                HStack(spacing: 4) {
                    Image(systemName: event.category.icon)
                        .font(.caption2)
                    Text(event.category.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.9))
                .foregroundColor(getCategoryColor(event.category))
                .cornerRadius(12)
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(event.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(event.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if event.isFree {
                        Text("FREE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                    } else if let price = event.price {
                        Text("DT\(Int(price))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
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
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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

struct EmptyEventsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No events found")
                .font(.headline)
            
            Text("Check back later for new events")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Profile Tab
struct ProfileTabContent: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let currentUser = authVM.currentAppUser {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple, Color.pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(currentUser.email.prefix(1)).uppercased())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .padding(.top, 20)
                        
                        VStack(spacing: 8) {
                            Text(currentUser.email)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                Text("User Account")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                            
                            Text("Member since \(currentUser.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .padding(.vertical)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Events")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            
                            
                            NavigationLink(destination: JoinedEventsView()) {
                                ProfileActionRow(
                                    icon: "ticket",
                                    title: "Events Joined",
                                    value: "\(eventVM.joinedEvents.count)",
                                    color: .blue
                                )
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            authVM.signOut()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Profile")
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

struct ProfileActionRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}



// MARK: - Joined Events'Vue

struct JoinedEventsView: View {
    @EnvironmentObject var eventVM: EventViewModel
    
    var body: some View {
        List(eventVM.joinedEvents) { event in
            NavigationLink(destination: EventDetailView(event: event)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                    Text(event.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Joined Events")
    }
}

struct EventDetailView: View {
    let event: Event
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventVM: EventViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(event.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(event.description)
                    .font(.body)
                
                Text("Location: \(event.location)")
                Text("Date: \(event.formattedDate)")
                
                // Bouton Join/Leave
                if let userId = authVM.user?.uid {
                    if event.isUserParticipating(userId: userId) {
                        Button("Leave Event") {
                            Task {
                                await eventVM.leaveEvent(event, userId: userId)
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else {
                        Button("Join Event") {
                            Task {
                                await eventVM.joinEvent(event, userId: userId)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    DashboardUserView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(AuthViewModel())
        .environmentObject(EventViewModel())
        .environmentObject(QuoteViewModel())
}
