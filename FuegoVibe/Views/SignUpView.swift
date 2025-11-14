import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        VStack(spacing: 30) {

            Text("Create Your Account")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.purple)

            VStack(spacing: 15) {

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }

            if !authVM.errorMessage.isEmpty {
                Text(authVM.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                if password != confirmPassword {
                    authVM.errorMessage = "Passwords do not match"
                } else if password.count < 6 {
                    authVM.errorMessage = "Password must be at least 6 characters"
                } else {
                    Task {
                        await authVM.signUp(email: email, password: password)
                        // Si l'inscription réussit, revenir à l'écran de connexion
                        if authVM.user != nil {
                            dismiss()
                        }
                    }
                }
            } label: {
                HStack {
                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign Up")
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(12)
            }
            .disabled(authVM.isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty)

            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
