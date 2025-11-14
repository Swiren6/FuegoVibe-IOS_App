//
//  ContentView.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
//

import SwiftUI
import SwiftData
import FirebaseFirestore

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authVM: AuthViewModel
    @Query private var items: [Item]

    var body: some View {
        TabView {
            // 🏠 Page principale
            NavigationSplitView {
                VStack {
                    // Badge de rôle
                    if let currentUser = authVM.currentAppUser {
                        HStack {
                            Text("Welcome, \(currentUser.email)")
                                .font(.caption)
                            Spacer()
                            // Badge Admin
                            if currentUser.isAdmin {
                                HStack(spacing: 4) {
                                    Image(systemName: "crown.fill")
                                        .font(.caption2)
                                    Text("Admin")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.2))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                    }
                    
                    List {
                        ForEach(items) { item in
                            NavigationLink {
                                Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                            } label: {
                                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                .navigationTitle("FuegoVibe 🔥")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            authVM.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            } detail: {
                Text("Select an item")
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // 👑 Admin (visible uniquement si admin)
            if authVM.isAdmin {
                NavigationView {
                    AdminPanelView()
                }
                .tabItem {
                    Label("Admin", systemImage: "crown.fill")
                }
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

// Panel Admin Simple
struct AdminPanelView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var users: [AppUser] = []
    @State private var isLoading = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading users...")
            } else {
                List(users) { user in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.email)
                            .font(.headline)
                        HStack {
                            Text("Role: \(user.role.rawValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            if user.isAdmin {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Admin Panel 👑")
        .toolbar {
            Button {
                Task { await loadUsers() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        .onAppear {
            Task { await loadUsers() }
        }
    }
    
    func loadUsers() async {
        isLoading = true
        
        do {
            let snapshot = try await db.collection("users").getDocuments()
            
            self.users = snapshot.documents.compactMap { doc -> AppUser? in
                let data = doc.data()
                guard let uid = data["uid"] as? String,
                      let email = data["email"] as? String else {
                    return nil
                }
                
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

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(AuthViewModel())
}
