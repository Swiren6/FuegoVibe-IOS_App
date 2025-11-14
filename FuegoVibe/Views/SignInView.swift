import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 30) {

            Text("Welcome to FuegoVibe🔥")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 15) {

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .textContentType(.password)
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
                Task {
                    await authVM.signIn(email: email, password: password)
                }
            } label: {
                HStack {
                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(12)
            }
            .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)

            NavigationLink("Don't have an account? Sign Up") {
                SignUpView()
            }
            .font(.footnote)
            .foregroundColor(.blue)

            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SignInView()
            .environmentObject(AuthViewModel())
    }
}
