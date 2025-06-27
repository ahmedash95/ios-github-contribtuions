import Combine
import SwiftUI

struct UserContributionView: View {
  let userSettings: UserSettings
  @State private var user: GitHubUser?
  @State private var contributions: [ContributionDay] = []
  @State private var isLoading = true
  @State private var errorMessage = ""
  @Environment(\.colorScheme) private var colorScheme

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
        userHeader
        Divider().padding(.vertical, 4)
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
  }

  private var userHeader: some View {
    HStack(spacing: 12) {
      AsyncImage(url: URL(string: user?.avatarUrl ?? "")) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
      } placeholder: {
        Circle()
          .fill(Color.gray.opacity(0.3))
          .overlay(
            Image(systemName: "person.fill")
              .font(.caption)
              .foregroundColor(.gray)
          )
      }
      .frame(width: 32, height: 32)
      .clipShape(Circle())
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
            Text("•")
              .font(.caption2)
              .foregroundColor(.secondary)

            Text("\(totalContributions) contributions")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }

      Spacer()
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
      async let userFetch = GitHubService.shared.fetchUser(username: userSettings.username)
      async let contributionsFetch = GitHubService.shared.fetchContributions(
        username: userSettings.username)

      let (fetchedUser, fetchedContributions) = try await (userFetch, contributionsFetch)

      await MainActor.run {
        self.user = fetchedUser
        self.contributions = fetchedContributions
        self.isLoading = false
      }
    } catch {
      await MainActor.run {
        self.errorMessage = "Failed to load data"
        self.isLoading = false
      }
    }
  }
}
