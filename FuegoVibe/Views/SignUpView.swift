//
//  SignUpView.swift
//  FuegoVibe
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var formOpacity: Double = 0
    @State private var formOffset: CGFloat = 20

    var formError: String {
        if !authVM.errorMessage.isEmpty { return authVM.errorMessage }
        return ""
    }

    var body: some View {
        ZStack {
            FV.Colors.background.ignoresSafeArea()

            RadialGradient(
                colors: [FV.Colors.fire.opacity(0.10), .clear],
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

                        Text("Create account")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(FV.Colors.primary)

                        Text("Join FuegoVibe today")
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

                        FVInputField(
                            placeholder: "Confirm password",
                            text: $confirmPassword,
                            isSecure: true,
                            icon: "lock.shield"
                        )

                        // Password match indicator
                        if !password.isEmpty && !confirmPassword.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.caption)
                                Text(password == confirmPassword ? "Passwords match" : "Passwords don't match")
                                    .font(.caption)
                                Spacer()
                            }
                            .foregroundColor(password == confirmPassword ? .green : .red)
                            .padding(.horizontal, 4)
                        }

                        FVErrorText(message: formError)
                            .padding(.top, 2)

                        FVPrimaryButton(
                            title: "Create Account",
                            isLoading: authVM.isLoading,
                            isDisabled: email.isEmpty || password.isEmpty || confirmPassword.isEmpty
                        ) {
                            if password != confirmPassword {
                                authVM.errorMessage = "Passwords do not match"
                            } else if password.count < 6 {
                                authVM.errorMessage = "Password must be at least 6 characters"
                            } else {
                                Task {
                                    await authVM.signUp(email: email, password: password)
                                    if authVM.user != nil { dismiss() }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 28)
                    .opacity(formOpacity)
                    .offset(y: formOffset)

                    // ── Footer ──
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(FV.Colors.secondary)
                        NavigationLink(destination: SignInView()) {
                            Text("Sign In")
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
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
