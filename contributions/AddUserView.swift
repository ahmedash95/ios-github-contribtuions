import Combine
import SwiftUI

struct AddUserView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var userStore: UserStore

  @State private var username = ""
  @State private var selectedThemeId = "github"
  @State private var isLoading = false
  @State private var errorMessage = ""

  var body: some View {
    NavigationView {
      Form {
        Section("GitHub Username") {
          TextField("Enter username", text: $username)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }

        Section("Chart Theme") {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(ContributionColorTheme.themes) { theme in
              ThemePreviewCard(
                theme: theme,
                isSelected: selectedThemeId == theme.id
              ) {
                selectedThemeId = theme.id
              }
            }
          }
          .padding(.vertical, 8)
        }

        if !errorMessage.isEmpty {
          Section {
            Text(errorMessage)
              .foregroundColor(.red)
              .font(.caption)
          }
        }
      }
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

struct ThemePreviewCard: View {
  let theme: ContributionColorTheme
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    VStack(spacing: 6) {
      Text(theme.name)
        .font(.caption2)
        .fontWeight(.medium)
        .lineLimit(1)

      HStack(spacing: 1) {
        ForEach(0..<5) { level in
          RoundedRectangle(cornerRadius: 1)
            .fill(theme.color(for: level))
            .frame(width: 10, height: 10)
        }
      }
    }
    .padding(6)
    .background(
      RoundedRectangle(cornerRadius: 6)
        .fill(Color(.systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 6)
            .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
        )
    )
    .onTapGesture {
      onTap()
    }
  }
}
