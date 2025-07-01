import Combine
import SwiftUI

struct UserContributionView: View {
  let userSettings: UserSettings
  let forceRefresh: Bool
  @State private var user: GitHubUser?
  @State private var contributions: [ContributionDay] = []
  @State private var isLoading = true
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
        HStack {
          Image(systemName: "exclamationmark.triangle")
            .foregroundColor(.orange)
          Text(errorMessage)
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
        .frame(height: 60)
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
    .onChange(of: forceRefresh) { _ in
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
            Text("• \(totalContributions) contributions")
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

  private var contributionChart: some View {
    ContributionChartView(
      contributions: contributions,
      userSettings: userSettings,
      compact: false
    )
  }

  private func loadData() async {
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

      await MainActor.run {
        self.user = fetchedUser
        self.contributions = fetchedContributions
        self.isLoading = false
      }
    } catch {
      await MainActor.run {
        self.errorMessage = ErrorHandler.getErrorMessage(for: error)
        self.isLoading = false
      }
    }
  }
}
