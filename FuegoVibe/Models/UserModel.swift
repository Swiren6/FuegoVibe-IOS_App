//
//  UserModel.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
//

import Foundation
import FirebaseFirestore

enum UserRole: String, Codable {
    case user = "user"
    case admin = "admin"
}

// Modèle User
struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var uid: String
    var email: String
    var role: UserRole
    var createdAt: Date
    var isAdmin: Bool {
        return role == .admin
    }
}
