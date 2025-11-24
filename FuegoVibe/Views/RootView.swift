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
                if let currentUser = authVM.currentAppUser {
                    if currentUser.isAdmin {
                        DashboardAdminView()
                    } else {
                        DashboardUserView()
                    }
                } else {
                    ProgressView("Loading...")
                }
            } else {
                WelcomeView()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
}
