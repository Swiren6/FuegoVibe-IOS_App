//
//  FuegoVibeApp.swift
//  FuegoVibe
//
//  FIXES:
//  - Removed SwiftData (ModelContainer, Item) — was never used
//  - Added UserViewModel to environment objects
//  - After applying this fix, you can safely delete Item.swift and ContentView.swift
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct FuegoVibeApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var eventViewModel = EventViewModel()
    @StateObject private var quoteViewModel = QuoteViewModel()
    @StateObject private var userViewModel = UserViewModel()   // NEW

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(eventViewModel)
                .environmentObject(quoteViewModel)
                .environmentObject(userViewModel)   // NEW
        }
    }
}
