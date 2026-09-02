//
//  DesignSystem.swift
//  FuegoVibe
//
//  Central design tokens and shared UI components.
//

import SwiftUI

// MARK: - Design Tokens

enum FV {

    // MARK: Colors
    enum Colors {
        static let background    = Color(red: 0.05, green: 0.04, blue: 0.08)
        static let surface       = Color(red: 0.11, green: 0.10, blue: 0.15)
        static let surfaceHigh   = Color(red: 0.17, green: 0.16, blue: 0.22)

        static let fire          = Color(red: 1.00, green: 0.42, blue: 0.21)
        static let fireDark      = Color(red: 0.95, green: 0.22, blue: 0.08)
        static let violet        = Color(red: 0.55, green: 0.24, blue: 0.93)

        static let primary       = Color.white
        static let secondary     = Color.white.opacity(0.55)
        static let tertiary      = Color.white.opacity(0.25)
        static let border        = Color.white.opacity(0.09)
        static let borderActive  = Color(red: 1.0, green: 0.42, blue: 0.21).opacity(0.40)
    }

    // MARK: Event Category Colors
    enum Category {
        static let music      = Color(red: 0.56, green: 0.35, blue: 0.97)  // Electric violet
        static let sports     = Color(red: 0.07, green: 0.75, blue: 0.52)  // Neon emerald
        static let arts       = Color(red: 0.97, green: 0.26, blue: 0.59)  // Hot magenta
        static let food       = Color(red: 1.00, green: 0.64, blue: 0.09)  // Amber fire
        static let business   = Color(red: 0.22, green: 0.55, blue: 1.00)  // Electric blue
        static let technology = Color(red: 0.02, green: 0.74, blue: 0.88)  // Neon cyan
        static let other      = Color(red: 0.58, green: 0.58, blue: 0.63)  // Cool gray

        static func color(for category: EventCategory) -> Color {
            switch category {
            case .music:      return music
            case .sports:     return sports
            case .arts:       return arts
            case .food:       return food
            case .business:   return business
            case .technology: return technology
            case .other:      return other
            }
        }
    }

    // MARK: Gradients
    static var fireGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.42, blue: 0.21), Color(red: 0.55, green: 0.24, blue: 0.93)],
            startPoint: .leading, endPoint: .trailing
        )
    }

    static var fireGradientVertical: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.65, blue: 0.21), Color(red: 0.55, green: 0.24, blue: 0.93)],
            startPoint: .top, endPoint: .bottom
        )
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.08, green: 0.06, blue: 0.13), Color(red: 0.03, green: 0.03, blue: 0.05)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

// MARK: - Shared UI Components

/// Dark-themed text field with fire accent border on focus
struct FVInputField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var icon: String? = nil
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 14) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(text.isEmpty ? FV.Colors.tertiary : FV.Colors.fire)
                    .frame(width: 20)
            }

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                }
            }
            .autocapitalization(.none)
            .foregroundColor(FV.Colors.primary)
            .tint(FV.Colors.fire)
            .font(.system(size: 16))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(FV.Colors.surface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(text.isEmpty ? FV.Colors.border : FV.Colors.borderActive, lineWidth: 1)
        )
    }
}

/// Full-width gradient primary button
struct FVPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(isDisabled ? AnyShapeStyle(FV.Colors.surfaceHigh) : AnyShapeStyle(FV.fireGradient))
            .cornerRadius(18)
            .shadow(color: isDisabled ? .clear : FV.Colors.fire.opacity(0.35), radius: 16, x: 0, y: 8)
        }
        .disabled(isDisabled || isLoading)
    }
}

/// Ghost secondary button
struct FVSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(FV.Colors.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(FV.Colors.surface)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FV.Colors.border, lineWidth: 1)
                )
        }
    }
}

/// Error message row
struct FVErrorText: View {
    let message: String

    var body: some View {
        if !message.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Navigation / Tab Bar Appearance

struct DarkNavigationAppearance: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                let nav = UINavigationBarAppearance()
                nav.configureWithOpaqueBackground()
                nav.backgroundColor = UIColor(FV.Colors.background)
                nav.titleTextAttributes = [.foregroundColor: UIColor.white]
                nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                UINavigationBar.appearance().standardAppearance = nav
                UINavigationBar.appearance().scrollEdgeAppearance = nav
                UINavigationBar.appearance().compactAppearance = nav
                UINavigationBar.appearance().tintColor = UIColor(FV.Colors.fire)

                let tab = UITabBarAppearance()
                tab.configureWithOpaqueBackground()
                tab.backgroundColor = UIColor(FV.Colors.surface)
                tab.stackedLayoutAppearance.selected.iconColor = UIColor(FV.Colors.fire)
                tab.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.4)
                tab.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(FV.Colors.fire)]
                tab.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
                UITabBar.appearance().standardAppearance = tab
                UITabBar.appearance().scrollEdgeAppearance = tab
            }
    }
}

extension View {
    func darkAppearance() -> some View {
        modifier(DarkNavigationAppearance())
    }
}
