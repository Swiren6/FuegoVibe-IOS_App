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
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
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
                Task {
                    await authVM.signIn(email: email, password: password)
                }
            } label: {
                Text("Sign In")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
            }

            NavigationLink("Don't have an account? Sign Up") {
                SignUpView()
            }
            .font(.footnote)
            .foregroundColor(.blue)

            Spacer()
        }
        .padding()
    }
}
