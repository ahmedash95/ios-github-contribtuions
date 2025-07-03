import SwiftUI

struct GitHubTokenSetupView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var token = ""
  @State private var isLoading = false
  @State private var errorMessage = ""
  @State private var showingSuccess = false

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        // Token input as the primary focus
        tokenInputSection

        if !errorMessage.isEmpty {
          errorSection
        }

        // Compact instructions
        instructionsSection

        Spacer()
      }
      .padding()
      .navigationTitle("GitHub Token")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveToken()
          }
          .disabled(token.isEmpty || isLoading)
        }
      }
      .alert("Token Saved!", isPresented: $showingSuccess) {
        Button("Continue") {
          dismiss()
        }
      } message: {
        Text("Your GitHub token has been securely saved to the Keychain.")
      }
    }
  }

  private var tokenInputSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("GitHub Personal Access Token")
        .font(.headline)

      SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $token)
        .textFieldStyle(.roundedBorder)
        .font(.system(.body, design: .monospaced))
        .autocapitalization(.none)
        .disableAutocorrection(true)

      Text("Securely stored in iOS Keychain")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }

  private var instructionsSection: some View {
    VStack(alignment: .leading) {
      Text("Need a token?")
        .font(.subheadline)
        .fontWeight(.medium)

      Button {
        openGitHubTokenPage()
      } label: {
        HStack {
          Image(systemName: "safari")
          Text("Open GitHub Tokens Page")
        }
        .font(.subheadline)
        .foregroundColor(.blue)
      }

      Text(
        "1. Generate new token (classic)\n2. Add note: 'Contributions App'\n3. Select 'read:user' scope\n4. Copy & paste above"
      )
      .font(.caption)
      .foregroundColor(.secondary)
      .lineLimit(nil)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
    .background(Color(.systemGray6))
    .cornerRadius(8)
  }

  private var errorSection: some View {
    HStack {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundColor(.orange)
      Text(errorMessage)
        .font(.caption)
        .foregroundColor(.orange)
    }
    .padding()
    .background(Color.orange.opacity(0.1))
    .cornerRadius(8)
  }

  private func openGitHubTokenPage() {
    if let url = URL(string: "https://github.com/settings/tokens") {
      UIApplication.shared.open(url)
    }
  }

  private func saveToken() {
    isLoading = true
    errorMessage = ""

    let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedToken.isEmpty else {
      errorMessage = "Please enter a valid token"
      isLoading = false
      return
    }

    guard trimmedToken.hasPrefix("ghp_") || trimmedToken.hasPrefix("github_pat_") else {
      errorMessage = "Token should start with 'ghp_' or 'github_pat_'"
      isLoading = false
      return
    }

    if GitHubService.shared.saveToken(trimmedToken) {
      showingSuccess = true
    } else {
      errorMessage = "Failed to save token to Keychain"
    }

    isLoading = false
  }
}
