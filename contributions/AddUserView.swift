import Combine
import Foundation
import SwiftUI

struct AddUserView: View {
  @Environment(\.dismiss) private var dismiss
  var userStore: UserStore

  @State private var username = ""
  @State private var selectedThemeId = "github"
  @State private var isLoading = false
  @State private var errorMessage = ""

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        Form {
          Section("GitHub Username") {
            TextField("Enter username", text: $username)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .onChange(of: username) { _ in
                // Clear error message when user starts typing
                if !errorMessage.isEmpty {
                  errorMessage = ""
                }
              }
          }

          if !errorMessage.isEmpty {
            HStack {
              Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
              Text(errorMessage)
                .foregroundColor(.red)
                .font(.caption)
            }
            .padding(.top, 8)
          }

          Section("Theme") {
            ThemeGridPicker(selectedThemeId: $selectedThemeId)
          }
        }
        .ignoresSafeArea(.keyboard)
        .navigationTitle("Add User")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              dismiss()
            }
          }

          ToolbarItem(placement: .confirmationAction) {
            Button("Add") {
              addUser()
            }
            .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
          }
        }
      }
    }
  }

  private func addUser() {
    let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

    // Final validation before adding
    if let validationError = ErrorHandler.getUsernameValidationError(
      for: trimmedUsername, existingUsers: userStore.users)
    {
      errorMessage = validationError
      return
    }

    isLoading = true
    errorMessage = ""

    Task {
      do {
        // Final GitHub existence check
        let _ = try await GitHubService.shared.fetchUser(username: trimmedUsername)
        await MainActor.run {
          userStore.addUser(trimmedUsername, colorThemeId: selectedThemeId)
          dismiss()
        }
      } catch {
        print("AddUser error: \(error)")
        await MainActor.run {
          errorMessage = ErrorHandler.getErrorMessage(for: error)
          isLoading = false
        }
      }
    }
  }

}

// Reusable theme grid picker for both AddUserView and SettingsView
struct ThemeGridPicker: View {
  @Binding var selectedThemeId: String
  @Environment(\.colorScheme) private var colorScheme

  let columns = [
    GridItem(.fixed(150), spacing: 20),
    GridItem(.fixed(150), spacing: 20),
  ]

  var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      LazyVGrid(columns: columns, spacing: 24) {
        ForEach(ContributionColorTheme.themes) { theme in
          ThemePreviewListItem(
            theme: theme,
            isSelected: selectedThemeId == theme.id
          ) {
            selectedThemeId = theme.id
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 8)
      .padding(.bottom, 8)
    }
  }
}
