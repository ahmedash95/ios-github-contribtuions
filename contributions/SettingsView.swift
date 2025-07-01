import Combine
import SwiftUI
import WidgetKit

struct SettingsView: View {
  var userStore: UserStore
  @Environment(\.dismiss) private var dismiss

  @State private var selectedUser: UserSettings?
  @State private var showingThemePicker = false
  @State private var showingTokenSetup = false
  @State private var showingTokenAlert = false
  @State private var showingFlushCacheAlert = false
  @State private var showingAddUser = false

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

        Section("Cache Management") {
          HStack {
            Image(systemName: "trash.fill")
              .foregroundColor(.orange)
            VStack(alignment: .leading) {
              Text("Flush Cache")
                .font(.headline)
              Text("Remove all cached data and fetch fresh data")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            Button("Clear All") {
              showingFlushCacheAlert = true
            }
            .buttonStyle(.bordered)
            .foregroundColor(.orange)
          }
        }

        Section("Users") {
          HStack {
            Image(systemName: "plus.circle.fill")
              .foregroundColor(.blue)
            Text("Add User")
              .font(.headline)
            Spacer()
            Button("Add") {
              showingAddUser = true
            }
            .buttonStyle(.bordered)
          }

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
        // Toolbar is empty - removed Done and Edit buttons
      }
      .sheet(isPresented: $showingThemePicker) {
        if let user = selectedUser {
          ThemePickerView(user: user, userStore: userStore)
        }
      }
      .sheet(isPresented: $showingTokenSetup) {
        GitHubTokenSetupView()
      }
      .sheet(isPresented: $showingAddUser) {
        AddUserView(userStore: userStore)
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
      .alert("Flush Cache", isPresented: $showingFlushCacheAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Clear All", role: .destructive) {
          DataManager.shared.clearCache()
          // Reload widget to reflect the cleared cache
          WidgetCenter.shared.reloadAllTimelines()
        }
      } message: {
        Text(
          "This will remove all cached contribution data, user profiles, and avatars. Fresh data will be fetched the next time you view contributions."
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
  var userStore: UserStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme

  @State private var selectedThemeId: String

  init(user: UserSettings, userStore: UserStore) {
    self.user = user
    self.userStore = userStore
    self._selectedThemeId = State(initialValue: user.colorThemeId)
  }

  let columns = [
    GridItem(.flexible(), spacing: 20),
    GridItem(.flexible(), spacing: 20),
  ]

  var body: some View {
    NavigationView {
      ScrollView {
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
        .padding(.top, 16)
      }
      .navigationTitle("Choose Theme")
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

struct ThemePreviewListItem: View {
  let theme: ContributionColorTheme
  let isSelected: Bool
  let onTap: () -> Void
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack(alignment: .topTrailing) {
      VStack(spacing: 14) {
        // Full-width contribution chart
        HStack {
          Spacer()
          ContributionChartPreview(theme: theme, colorScheme: colorScheme)
          Spacer()
        }
        // Theme name
        Text(theme.name)
          .font(.headline)
          .fontWeight(.medium)
          .multilineTextAlignment(.center)
      }
      .padding(.vertical, 18)
      .padding(.horizontal, 16)
      .background(
        RoundedRectangle(cornerRadius: 18)
          .fill(Color(.systemBackground))
          .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
          .overlay(
            RoundedRectangle(cornerRadius: 18)
              .stroke(
                isSelected ? Color.blue : Color(.systemGray5), lineWidth: isSelected ? 2.5 : 1)
          )
      )
      // Checkmark
      if isSelected {
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(.blue)
          .font(.title)
          .padding([.top, .trailing], 12)
      }
    }
    .padding(.vertical, 6)
    .onTapGesture { onTap() }
  }
}

struct ContributionChartPreview: View {
  let theme: ContributionColorTheme
  let colorScheme: ColorScheme

  // Precompute which boxes are empty for a consistent preview
  private var emptyIndices: Set<Int> {
    var indices = Set<Int>()
    var rng = SeededGenerator(seed: 42)
    while indices.count < 6 {
      indices.insert(Int.random(in: 0..<49, using: &rng))
    }
    return indices
  }

  var body: some View {
    HStack(spacing: 2) {
      ForEach(0..<7, id: \.self) { weekIndex in
        VStack(spacing: 2) {
          ForEach(0..<7, id: \.self) { dayIndex in
            let flatIndex = weekIndex * 7 + dayIndex
            let level =
              emptyIndices.contains(flatIndex)
              ? 0
              : Int((flatIndex * 3) % 4) + 1  // levels 1-4, varied
            RoundedRectangle(cornerRadius: 2)
              .fill(theme.color(for: level, isDarkMode: colorScheme == .dark))
              .frame(width: 10, height: 10)
          }
        }
      }
    }
    .padding(6)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(.systemGray6))
    )
  }
}

// Helper for deterministic randomization
struct SeededGenerator: RandomNumberGenerator {
  private var state: UInt64
  init(seed: UInt64) { self.state = seed }
  mutating func next() -> UInt64 {
    state = state &* 6_364_136_223_846_793_005 &+ 1
    return state
  }
}
