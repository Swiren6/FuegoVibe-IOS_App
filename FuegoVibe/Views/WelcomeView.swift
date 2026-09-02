//
//  WelcomeView.swift
//  FuegoVibe
//

import SwiftUI

struct WelcomeView: View {
    @State private var glowScale: CGFloat = 1.0
    @State private var flameScale: CGFloat = 0.85
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 40
    @State private var buttonsOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                FV.Colors.background.ignoresSafeArea()

                // Ambient fire glow behind logo
                RadialGradient(
                    colors: [
                        FV.Colors.fire.opacity(0.18),
                        FV.Colors.violet.opacity(0.08),
                        .clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.38),
                    startRadius: 0,
                    endRadius: 300
                )
                .scaleEffect(glowScale)
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // ── Logo ──
                    ZStack {
                        // Outer rings
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(
                                    FV.Colors.fire.opacity(0.07 - Double(i) * 0.02),
                                    lineWidth: 1.5
                                )
                                .frame(
                                    width: 160 + CGFloat(i * 45),
                                    height: 160 + CGFloat(i * 45)
                                )
                                .scaleEffect(glowScale)
                        }

                        // Logo circle
                        Circle()
                            .fill(FV.Colors.surface)
                            .frame(width: 132, height: 132)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [FV.Colors.fire.opacity(0.5), FV.Colors.violet.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: FV.Colors.fire.opacity(0.4), radius: 30, x: 0, y: 0)

                        // Flame icon
                        Image(systemName: "flame.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 58, height: 58)
                            .foregroundStyle(FV.fireGradientVertical)
                            .shadow(color: FV.Colors.fire.opacity(0.9), radius: 18)
                            .scaleEffect(flameScale)
                    }
                    .opacity(logoOpacity)

                    Spacer().frame(height: 48)

                    // ── Title block ──
                    VStack(spacing: 14) {
                        // App name with shimmer gradient
                        ZStack {
                            Text("FuegoVibe")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundStyle(FV.fireGradient)

                            // Shimmer overlay
                            Text("FuegoVibe")
                                .font(.system(size: 50, weight: .bold, design: .rounded))
                                .foregroundColor(.clear)
                                .overlay(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.25), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .offset(x: shimmerOffset)
                                    .frame(width: 300)
                                )
                                .mask(
                                    Text("FuegoVibe")
                                        .font(.system(size: 50, weight: .bold, design: .rounded))
                                )
                        }

                        Text("Experience Events Like Never Before")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(FV.Colors.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(titleOpacity)

                    Spacer()

                    // ── Feature pills ──
                    HStack(spacing: 12) {
                        FeaturePill(icon: "music.note", label: "Music")
                        FeaturePill(icon: "sportscourt", label: "Sports")
                        FeaturePill(icon: "paintpalette", label: "Arts")
                        FeaturePill(icon: "fork.knife", label: "Food")
                    }
                    .opacity(titleOpacity)

                    Spacer().frame(height: 48)

                    // ── CTA Buttons ──
                    VStack(spacing: 14) {
                        NavigationLink(destination: SignUpView()) {
                            HStack {
                                Text("Get Started")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(FV.fireGradient)
                            .cornerRadius(18)
                            .shadow(color: FV.Colors.fire.opacity(0.4), radius: 16, x: 0, y: 8)
                        }
                        .buttonStyle(PlainButtonStyle())

                        NavigationLink(destination: SignInView()) {
                            Text("I already have an account")
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
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 52)
                    .offset(y: buttonsOffset)
                    .opacity(buttonsOpacity)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                // Logo entrance
                withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
                    logoOpacity = 1
                    flameScale = 1.0
                }
                // Title entrance
                withAnimation(.easeOut(duration: 0.7).delay(0.35)) {
                    titleOpacity = 1
                }
                // Buttons slide up
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.55)) {
                    buttonsOffset = 0
                    buttonsOpacity = 1
                }
                // Glow pulse loop
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                    glowScale = 1.18
                }
                // Flame pulse loop
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5)) {
                    flameScale = 1.06
                }
                // Shimmer sweep
                withAnimation(.linear(duration: 2.0).delay(1.0).repeatForever(autoreverses: false)) {
                    shimmerOffset = 300
                }
            }
        }
    }
}

struct FeaturePill: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundColor(FV.Colors.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(FV.Colors.surface)
        .cornerRadius(20)
        .overlay(
            Capsule().stroke(FV.Colors.border, lineWidth: 1)
        )
    }
}

#Preview {
    WelcomeView()
}
