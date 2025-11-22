//
//  RootView.swift
//  FuegoVibe
//
//  Created by mac on 14/11/2025.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        Group {
            if authVM.user != nil {
                //  Utilisateur connecté
                if let currentUser = authVM.currentAppUser {
                    // Router vers le bon dashboard selon le rôle
                    if currentUser.isAdmin {
                        //  Admin → Dashboard Admin
                        DashboardAdminView()
                    } else {
                        //  User → Dashboard User
                        DashboardUserView()
                    }
                } else {
                    // Chargement des données utilisateur
                    ProgressView("Loading...")
                }
            } else {
                // Pas d'utilisateur → Page d'accueil
                WelcomeView()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
}
