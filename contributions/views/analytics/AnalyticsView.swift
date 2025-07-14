import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var userStore: UserStore
    @State private var contributions: [String: [ContributionDay]] = [:]
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                if userStore.users.isEmpty {
                    Text("Add users to view analytics")
                        .foregroundColor(.secondary)
                        .padding()
                } else if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    VStack(spacing: 24) {
                        StreakChart(users: userStore.users, data: contributions)
                        SevenDayContributionsBarChart(users: userStore.users, data: contributions)
                        MonthlyTotalsPieChart(users: userStore.users, data: contributions)
                        DailyAverageLineChart(users: userStore.users, data: contributions)
                    }
                    .padding()
                }
            }
            .navigationTitle("Analytics")
            .task {
                await loadData()
            }
        }
    }

    private func loadData() async {
        var temp: [String: [ContributionDay]] = [:]
        for user in userStore.users {
            do {
                let data = try await GitHubService.shared.fetchContributions(username: user.username)
                temp[user.username] = data
            } catch {
                print("AnalyticsView: failed to fetch contributions for \(user.username) -> \(error)")
            }
        }
        await MainActor.run {
            self.contributions = temp
            self.isLoading = false
        }
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(UserStore())
}
