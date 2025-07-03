import Combine
import SwiftUI

struct UserContributionView: View {
  let userSettings: UserSettings
  let forceRefresh: Bool
  @State private var user: GitHubUser?
  @State private var contributions: [ContributionDay] = []
  @State private var isLoading = false
  @State private var errorMessage = ""
  @Environment(\.colorScheme) private var colorScheme

  private var currentStreak: Int {
    var streak = 0
    for day in contributions.reversed() {
      if day.contributionCount > 0 {
        streak += 1
      } else {
        break
      }
    }
    return streak
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if isLoading {
        HStack {
          ProgressView()
            .scaleEffect(0.8)
          Text("Loading...")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
        .frame(height: 60)
      } else if !errorMessage.isEmpty {
        VStack(spacing: 8) {
          HStack {
            Image(systemName: "exclamationmark.triangle")
              .foregroundColor(.orange)
            Text(errorMessage)
              .font(.caption)
              .foregroundColor(.secondary)
            Spacer()
          }

          Button("Retry") {
            Task {
              await loadData()
            }
          }
          .font(.caption)
          .foregroundColor(.blue)
        }
        .frame(height: 80)
      } else {
        userHeader.padding(.bottom, 4)
        contributionChart
      }
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color(.systemGray5), lineWidth: 1)
        )
    )
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .task {
      await loadData()
    }
    .onChange(of: forceRefresh) { _, _ in
      Task {
        await loadData()
      }
    }
  }

  private var userHeader: some View {
    HStack(spacing: 12) {
      CachedAvatarView(username: userSettings.username, size: 32)
        .overlay(
          Circle()
            .stroke(
              userSettings.colorTheme.color(for: 4, isDarkMode: colorScheme == .dark), lineWidth: 2)
        )

      VStack(alignment: .leading, spacing: 1) {
        Text(user?.name ?? user?.login ?? userSettings.username)
          .font(.subheadline)
          .fontWeight(.medium)
          .lineLimit(1)

        HStack(spacing: 4) {
          Text("@\(user?.login ?? userSettings.username)")
            .font(.caption2)
            .foregroundColor(.secondary)

          if !contributions.isEmpty {
            Text("• \(formatContributions(totalContributions)) contributions")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }

      Spacer()

      // Streak indicator badge

      if currentStreak > 0 {
        HStack(spacing: 4) {
          Image(systemName: "flame.fill")
            .font(.caption2)
            .foregroundColor(
              userSettings.colorTheme.color(for: 4, isDarkMode: colorScheme == .dark))
          Text("\(currentStreak)")
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(
              userSettings.colorTheme.color(for: 4, isDarkMode: colorScheme == .dark))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(
              userSettings.colorTheme.color(for: 4, isDarkMode: colorScheme == .dark).opacity(0.1))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(
              userSettings.colorTheme.color(for: 4, isDarkMode: colorScheme == .dark).opacity(0.3),
              lineWidth: 1)
        )
      }
    }
  }

  private var totalContributions: Int {
    contributions.reduce(0) { $0 + $1.contributionCount }
  }

  private func formatContributions(_ count: Int) -> String {
    if count >= 1000 {
      let thousands = Double(count) / 1000.0
      if thousands.truncatingRemainder(dividingBy: 1) == 0 {
        return "\(Int(thousands))k"
      } else {
        return String(format: "%.1fk", thousands)
      }
    }
    return "\(count)"
  }

  private var contributionChart: some View {
    ContributionChartView(
      contributions: contributions,
      userSettings: userSettings,
      compact: false
    )
  }

  private func loadData() async {
    print(
      "🔄 UserContributionView - Starting loadData for \(userSettings.username), forceRefresh: \(forceRefresh)"
    )

    // Check for cached data first
    let cachedUser = DataManager.shared.getCachedUser(for: userSettings.username)
    let cachedContributions = DataManager.shared.getCachedContributions(for: userSettings.username)

    print(
      "📦 UserContributionView - Cached user: \(cachedUser != nil), Cached contributions: \(cachedContributions != nil)"
    )

    // If we have cached data and not forcing refresh, use it immediately
    if !forceRefresh, let cachedUser = cachedUser, let cachedContributions = cachedContributions {
      print("✅ UserContributionView - Using cached data for \(userSettings.username)")
      await MainActor.run {
        self.user = cachedUser
        self.contributions = cachedContributions
        self.isLoading = false
        self.errorMessage = ""
      }
      return
    }

    // If we have partial cached data, use it while loading fresh data
    if !forceRefresh {
      if let cachedUser = cachedUser {
        await MainActor.run {
          self.user = cachedUser
        }
      }
      if let cachedContributions = cachedContributions {
        await MainActor.run {
          self.contributions = cachedContributions
        }
      }

      // If we have both user and contributions cached, we're done
      if cachedUser != nil && cachedContributions != nil {
        print("✅ UserContributionView - Using complete cached data for \(userSettings.username)")
        await MainActor.run {
          self.isLoading = false
          self.errorMessage = ""
        }
        return
      }
    }

    // Show loading and fetch fresh data
    await MainActor.run {
      self.isLoading = true
      self.errorMessage = ""
    }

    print("🔄 UserContributionView - Fetching fresh data for \(userSettings.username)")

    do {
      let userFetch: Task<GitHubUser, Error>
      let contributionsFetch: Task<[ContributionDay], Error>

      if forceRefresh {
        // Use force refresh methods that bypass cache
        userFetch = Task {
          try await GitHubService.shared.fetchUserForceRefresh(username: userSettings.username)
        }
        contributionsFetch = Task {
          try await GitHubService.shared.fetchContributionsForceRefresh(
            username: userSettings.username)
        }
      } else {
        // Use normal methods that respect cache
        userFetch = Task {
          try await GitHubService.shared.fetchUser(username: userSettings.username)
        }
        contributionsFetch = Task {
          try await GitHubService.shared.fetchContributions(username: userSettings.username)
        }
      }

      let (fetchedUser, fetchedContributions) = try await (
        userFetch.value, contributionsFetch.value
      )

      print("✅ UserContributionView - Successfully fetched data for \(userSettings.username)")

      // Download and cache avatar image
      if let avatarUrl = URL(string: fetchedUser.avatarUrl) {
        let (imageData, _) = try await URLSession.shared.data(from: avatarUrl)
        DataManager.shared.cacheAvatar(imageData, for: userSettings.username)
      }

      await MainActor.run {
        self.user = fetchedUser
        self.contributions = fetchedContributions
        self.isLoading = false
        self.errorMessage = ""  // Clear any previous error messages
      }
    } catch {
      print("❌ UserContributionView - Failed to load data for \(userSettings.username): \(error)")
      await MainActor.run {
        self.errorMessage = ErrorHandler.getErrorMessage(for: error)
        self.isLoading = false
      }
    }
  }
}
