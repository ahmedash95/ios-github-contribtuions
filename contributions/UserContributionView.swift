import SwiftUI
import Combine

struct UserContributionView: View {
    let userSettings: UserSettings
    @State private var user: GitHubUser?
    @State private var contributions: [ContributionDay] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                contributionChart
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
        )
        .task {
            await loadData()
        }
    }
    
    private var userHeader: some View {
        HStack(spacing: 8) {
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
            .frame(width: 28, height: 28)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 1) {
                Text(user?.name ?? user?.login ?? userSettings.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("@\(user?.login ?? userSettings.username)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var contributionChart: some View {
        ContributionChartView(
            contributions: contributions,
            customColor: Color(hex: userSettings.customColor),
            compact: false
        )
    }
    
    private func loadData() async {
        do {
            async let userFetch = GitHubService.shared.fetchUser(username: userSettings.username)
            async let contributionsFetch = GitHubService.shared.fetchContributions(username: userSettings.username)
            
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