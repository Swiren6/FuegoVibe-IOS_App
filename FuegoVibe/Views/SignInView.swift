//
//  SignInView.swift
//  FuegoVibe
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var formOpacity: Double = 0
    @State private var formOffset: CGFloat = 20

    var body: some View {
        ZStack {
            FV.Colors.background.ignoresSafeArea()

            // Subtle top glow
            RadialGradient(
                colors: [FV.Colors.violet.opacity(0.12), .clear],
                center: .top, startRadius: 0, endRadius: 350
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Header ──
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(FV.Colors.surface)
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Circle()
                                        .stroke(FV.Colors.fire.opacity(0.4), lineWidth: 1.5)
                                )
                                .shadow(color: FV.Colors.fire.opacity(0.3), radius: 16)

                            Image(systemName: "flame.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundStyle(FV.fireGradientVertical)
                        }
                        .padding(.top, 20)

                        Text("Welcome back")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(FV.Colors.primary)

                        Text("Sign in to your account")
                            .font(.system(size: 15))
                            .foregroundColor(FV.Colors.secondary)
                    }
                    .padding(.bottom, 40)

                    // ── Form ──
                    VStack(spacing: 14) {
                        FVInputField(
                            placeholder: "Email address",
                            text: $email,
                            icon: "envelope",
                            keyboard: .emailAddress
                        )

                        FVInputField(
                            placeholder: "Password",
                            text: $password,
                            isSecure: true,
                            icon: "lock"
                        )

                        FVErrorText(message: authVM.errorMessage)
                            .padding(.top, 2)

                        FVPrimaryButton(
                            title: "Sign In",
                            isLoading: authVM.isLoading,
                            isDisabled: email.isEmpty || password.isEmpty
                        ) {
                            Task { await authVM.signIn(email: email, password: password) }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 28)
                    .opacity(formOpacity)
                    .offset(y: formOffset)

                    // ── Footer ──
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(FV.Colors.secondary)
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .foregroundStyle(FV.fireGradient)
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.system(size: 15))
                    .padding(.top, 28)
                    .opacity(formOpacity)
                }
                .padding(.vertical, 20)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                formOpacity = 1
                formOffset = 0
            }
        }
    }
}

#Preview {
    NavigationView {
        SignInView()
            .environmentObject(AuthViewModel())
    }
}
