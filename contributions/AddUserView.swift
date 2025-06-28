import Combine
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
          }

          if !errorMessage.isEmpty {
            Text(errorMessage)
              .foregroundColor(.red)
              .font(.caption)
              .padding(.top, 8)
          }
        }
        .frame(maxHeight: 180)

        // Theme picker takes the rest of the space
        ThemeGridPicker(selectedThemeId: $selectedThemeId)
          .frame(maxHeight: .infinity)
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
          .disabled(username.isEmpty || isLoading)
        }
      }
    }
  }

  private func addUser() {
    isLoading = true
    errorMessage = ""

    Task {
      do {
        _ = try await GitHubService.shared.fetchUser(username: username)

        await MainActor.run {
          userStore.addUser(username, colorThemeId: selectedThemeId)
          dismiss()
        }
      } catch {
        await MainActor.run {
          errorMessage = "User not found or network error"
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
    GridItem(.flexible(), spacing: 20),
    GridItem(.flexible(), spacing: 20),
  ]

  var body: some View {
    ScrollView(.vertical, showsIndicators: false) {
      LazyVGrid(columns: columns, spacing: 20) {
        ForEach(ContributionColorTheme.themes) { theme in
          ThemePreviewListItem(
            theme: theme,
            isSelected: selectedThemeId == theme.id
          ) {
            selectedThemeId = theme.id
          }
          .padding(.horizontal, 4)
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 8)
      .padding(.bottom, 8)
    }
    .frame(minHeight: 220, maxHeight: 340)  // Adjust as needed for form
  }
}
