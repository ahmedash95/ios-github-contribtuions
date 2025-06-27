import Combine
import SwiftUI

struct SettingsView: View {
  @ObservedObject var userStore: UserStore
  @Environment(\.dismiss) private var dismiss

  @State private var selectedUser: UserSettings?
  @State private var showingThemePicker = false
  @State private var showingTokenSetup = false
  @State private var showingTokenAlert = false

  var body: some View {
    NavigationView {
      List {
        Section("GitHub Token") {
          HStack {
            Image(systemName: "key.fill")
              .foregroundColor(.blue)
            VStack(alignment: .leading) {
              Text("Access Token")
                .font(.headline)
              Text(GitHubService.shared.isTokenConfigured() ? "Configured" : "Not Set")
                .font(.caption)
                .foregroundColor(GitHubService.shared.isTokenConfigured() ? .green : .orange)
            }
            Spacer()
            Button(GitHubService.shared.isTokenConfigured() ? "Update" : "Setup") {
              showingTokenSetup = true
            }
            .buttonStyle(.bordered)
          }

          if GitHubService.shared.isTokenConfigured() {
            Button("Remove Token", role: .destructive) {
              showingTokenAlert = true
            }
          }
        }

        Section("Users") {
          if userStore.users.isEmpty {
            Text("No users added")
              .foregroundColor(.secondary)
              .font(.caption)
          } else {
            HStack {
              Text("Drag to reorder users")
                .font(.caption)
                .foregroundColor(.secondary)
              Spacer()
            }
            .padding(.vertical, 4)

            ForEach(userStore.users, id: \.username) { user in
              HStack {
                VStack(alignment: .leading) {
                  Text("@\(user.username)")
                    .font(.headline)
                  Text("Chart Theme")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                ThemePreviewSmall(theme: user.colorTheme)
                  .onTapGesture {
                    selectedUser = user
                    showingThemePicker = true
                  }
              }
              .swipeActions(edge: .trailing) {
                Button("Delete", role: .destructive) {
                  userStore.removeUser(user.username)
                }
              }
            }
            .onMove(perform: moveUsers)
          }
        }

        Section("About") {
          HStack {
            Image(systemName: "info.circle")
              .foregroundColor(.blue)
            Text("Version 1.0")
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            dismiss()
          }
        }

        if !userStore.users.isEmpty {
          ToolbarItem(placement: .navigationBarLeading) {
            EditButton()
          }
        }
      }
      .sheet(isPresented: $showingThemePicker) {
        if let user = selectedUser {
          ThemePickerView(user: user, userStore: userStore)
        }
      }
      .sheet(isPresented: $showingTokenSetup) {
        GitHubTokenSetupView()
      }
      .alert("Remove GitHub Token", isPresented: $showingTokenAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Remove", role: .destructive) {
          _ = GitHubService.shared.clearToken()
        }
      } message: {
        Text(
          "This will remove your GitHub token from the secure Keychain. You'll need to set it up again to view contribution data."
        )
      }
    }
  }

  private func moveUsers(from source: IndexSet, to destination: Int) {
    var users = userStore.users
    users.move(fromOffsets: source, toOffset: destination)
    userStore.updateUserOrder(users)
  }
}

struct ThemePreviewSmall: View {
  let theme: ContributionColorTheme

  var body: some View {
    HStack(spacing: 2) {
      ForEach(0..<5) { level in
        RoundedRectangle(cornerRadius: 1)
          .fill(theme.color(for: level))
          .frame(width: 8, height: 8)
      }
    }
    .padding(4)
    .background(
      RoundedRectangle(cornerRadius: 4)
        .fill(Color(.systemGray6))
    )
  }
}

struct ThemePickerView: View {
  let user: UserSettings
  @ObservedObject var userStore: UserStore
  @Environment(\.dismiss) private var dismiss

  @State private var selectedThemeId: String

  init(user: UserSettings, userStore: UserStore) {
    self.user = user
    self.userStore = userStore
    self._selectedThemeId = State(initialValue: user.colorThemeId)
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("Choose a theme for @\(user.username)")
          .font(.headline)
          .padding()

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
          ForEach(ContributionColorTheme.themes) { theme in
            ThemePreviewCard(
              theme: theme,
              isSelected: selectedThemeId == theme.id
            ) {
              selectedThemeId = theme.id
            }
          }
        }
        .padding()

        Spacer()
      }
      .navigationTitle("Theme Picker")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            userStore.updateUserColor(user.username, colorThemeId: selectedThemeId)
            dismiss()
          }
        }
      }
    }
  }
}
