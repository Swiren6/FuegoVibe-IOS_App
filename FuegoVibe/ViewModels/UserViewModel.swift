//
//  UserViewModel.swift
//  FuegoVibe
//


import Foundation
import Combine
import FirebaseFirestore

@MainActor
class UserViewModel: ObservableObject {
    @Published var users: [AppUser] = []
    @Published var isLoading = false
    @Published var errorMessage = ""

    private let db = Firestore.firestore()

    // MARK: - Computed helpers

    var totalUsers: Int { users.count }
    var totalAdmins: Int { users.filter { $0.isAdmin }.count }
    var recentUsers: [AppUser] {
        Array(users.sorted { $0.createdAt > $1.createdAt }.prefix(5))
    }

    // MARK: - Fetch

    func fetchAllUsers() async {
        isLoading = true
        errorMessage = ""

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
            print("✅ Loaded \(users.count) users")
        } catch {
            print("❌ Error loading users: \(error)")
            errorMessage = "Failed to load users"
        }

        isLoading = false
    }
}
