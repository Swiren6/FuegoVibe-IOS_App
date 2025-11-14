import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel

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
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                SecureField("Confirm Password", text: $confirmPassword)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }

            if !authVM.errorMessage.isEmpty {
                Text(authVM.errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button {
                if password == confirmPassword {
                    Task {
                        await authVM.signUp(email: email, password: password)
                    }
                } else {
                    authVM.errorMessage = "Passwords do not match"
                }
            } label: {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
    }
}
