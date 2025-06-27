import SwiftUI
import WidgetKit
import Combine

struct ContributionEntry: TimelineEntry {
    let date: Date
    let users: [UserWidgetData]
}

struct UserWidgetData {
    let username: String
    let avatarUrl: String?
    let contributions: [ContributionDay]
    let customColor: String
}

struct ContributionProvider: TimelineProvider {
    func placeholder(in context: Context) -> ContributionEntry {
        ContributionEntry(date: Date(), users: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ContributionEntry) -> Void) {
        let entry = ContributionEntry(date: Date(), users: [])
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ContributionEntry>) -> Void) {
        Task {
            let userStore = UserStore()
            var widgetUsers: [UserWidgetData] = []
            
            let maxUsers = getMaxUsers(for: context.family)
            let usersToShow = Array(userStore.users.prefix(maxUsers))
            
            for userSettings in usersToShow {
                do {
                    let user = try await GitHubService.shared.fetchUser(username: userSettings.username)
                    let contributions = try await GitHubService.shared.fetchContributions(username: userSettings.username, days: 7)
                    
                    widgetUsers.append(UserWidgetData(
                        username: userSettings.username,
                        avatarUrl: user.avatarUrl,
                        contributions: contributions,
                        customColor: userSettings.customColor
                    ))
                } catch {
                    continue
                }
            }
            
            let entry = ContributionEntry(date: Date(), users: widgetUsers)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
    
    private func getMaxUsers(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 2
        case .systemLarge:
            return 4
        default:
            return 1
        }
    }
}

struct ContributionWidgetView: View {
    let entry: ContributionEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.users.isEmpty {
                emptyState
            } else {
                switch family {
                case .systemSmall:
                    smallWidget
                case .systemMedium:
                    mediumWidget
                case .systemLarge:
                    largeWidget
                default:
                    smallWidget
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private var emptyState: some View {
        VStack {
            Image(systemName: "chart.dots.scatter")
                .font(.title)
                .foregroundColor(.secondary)
            Text("No Users")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let user = entry.users.first {
                userHeader(for: user, showAvatar: true)
                miniContributionChart(for: user)
            }
        }
        .padding(12)
    }
    
    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(entry.users.prefix(2).enumerated()), id: \.offset) { index, user in
                VStack(alignment: .leading, spacing: 4) {
                    userHeader(for: user, showAvatar: false)
                    miniContributionChart(for: user)
                }
                
                if index < min(entry.users.count, 2) - 1 {
                    Divider()
                }
            }
        }
        .padding(12)
    }
    
    private var largeWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(entry.users.prefix(4).enumerated()), id: \.offset) { index, user in
                HStack(spacing: 8) {
                    userHeader(for: user, showAvatar: true)
                    Spacer()
                    miniContributionChart(for: user)
                }
                
                if index < min(entry.users.count, 4) - 1 {
                    Divider()
                }
            }
        }
        .padding(12)
    }
    
    private func userHeader(for user: UserWidgetData, showAvatar: Bool) -> some View {
        HStack(spacing: 6) {
            if showAvatar {
                AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 20, height: 20)
                .clipShape(Circle())
            }
            
            Text("@\(user.username)")
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }
    
    private func miniContributionChart(for user: UserWidgetData) -> some View {
        ContributionChartView(
            contributions: user.contributions,
            customColor: Color(hex: user.customColor),
            compact: true
        )
        .scaleEffect(0.7)
    }
    
    private func getColor(for count: Int, customColor: Color) -> Color {
        let intensity = GitHubService.shared.getContributionIntensity(count: count)
        if intensity == 0.0 {
            return Color(.systemGray5)
        } else {
            return customColor.opacity(max(0.3, intensity))
        }
    }
}

struct ContributionWidget: Widget {
    let kind: String = "ContributionWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ContributionProvider()) { entry in
            ContributionWidgetView(entry: entry)
        }
        .configurationDisplayName("GitHub Contributions")
        .description("View your GitHub contribution activity.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}