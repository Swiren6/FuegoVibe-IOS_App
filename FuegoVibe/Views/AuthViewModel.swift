//
//  AuthViewModel.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
//

import Foundation
import Combine  // ✅ AJOUT CRITIQUE
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var errorMessage = ""
    @Published var isLoading = false

    init() {
        // Observer les changements d'état d'authentification
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func signUp(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.user = result.user
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            errorMessage = ""
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
