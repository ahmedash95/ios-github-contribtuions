import SwiftUI

struct GitHubTokenSetupView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var token = ""
  @State private var isLoading = false
  @State private var errorMessage = ""
  @State private var showingSuccess = false

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          headerSection
          instructionsSection
          tokenInputSection

          if !errorMessage.isEmpty {
            errorSection
          }

          Spacer()
        }
        .padding()
      }
      .navigationTitle("GitHub Setup")
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

  private var headerSection: some View {
    VStack(spacing: 12) {
      Image(systemName: "key.fill")
        .font(.system(size: 48))
        .foregroundColor(.blue)

      Text("GitHub Access Token Required")
        .font(.title2)
        .fontWeight(.semibold)
        .multilineTextAlignment(.center)

      Text(
        "To display your contribution data, we need a GitHub Personal Access Token with read permissions."
      )
      .font(.body)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
    }
  }

  private var instructionsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Setup Instructions:")
        .font(.headline)

      VStack(alignment: .leading, spacing: 12) {
        instructionStep(
          number: "1",
          title: "Generate Token",
          description: "Click the button below to open GitHub's token page"
        )

        Button {
          openGitHubTokenPage()
        } label: {
          HStack {
            Image(systemName: "safari")
            Text("Open GitHub Tokens Page")
          }
          .font(.subheadline)
          .foregroundColor(.white)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(Color.blue)
          .cornerRadius(8)
        }

        instructionStep(
          number: "2",
          title: "Configure Token",
          description:
            "• Click 'Generate new token (classic)'\n• Add a note like 'Contributions App'\n• Select 'read:user' scope\n• Click 'Generate token'"
        )

        instructionStep(
          number: "3",
          title: "Copy & Paste",
          description: "Copy the generated token and paste it below"
        )
      }
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }

  private var tokenInputSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("GitHub Personal Access Token")
        .font(.headline)

      SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $token)
        .textFieldStyle(.roundedBorder)
        .font(.system(.body, design: .monospaced))

      Text("Your token will be securely stored in the iOS Keychain")
        .font(.caption)
        .foregroundColor(.secondary)
    }
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

  private func instructionStep(number: String, title: String, description: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Text(number)
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .frame(width: 24, height: 24)
        .background(Color.blue)
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.medium)

        Text(description)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()
    }
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
