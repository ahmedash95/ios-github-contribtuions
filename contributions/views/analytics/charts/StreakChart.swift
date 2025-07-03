import Charts
import SwiftUI

struct StreakChart: View {
  enum TimeFrame: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    var id: String { rawValue }
    var days: Int { self == .week ? 7 : 30 }
  }

  let users: [UserSettings]
  let data: [String: [ContributionDay]]
  @State private var frame: TimeFrame = .week

  private func streak(for user: UserSettings) -> Int {
    guard let contributions = data[user.username] else { return 0 }
    let recent = contributions.suffix(frame.days)
    var count = 0
    for day in recent.reversed() {
      if day.contributionCount > 0 { count += 1 } else { break }
    }
    return count
  }

  private var sortedUsers: [UserSettings] {
    users.sorted { streak(for: $0) > streak(for: $1) }
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text("On Fire 🔥")
        .font(.headline)

      Picker("", selection: $frame) {
        ForEach(TimeFrame.allCases) { tf in
          Text(tf.rawValue).tag(tf)
        }
      }
      .pickerStyle(.segmented)
      .padding(.vertical, 4)

      Chart {
        ForEach(sortedUsers.prefix(5), id: \.username) { user in
          BarMark(
            x: .value("User", user.username),
            y: .value("Streak", streak(for: user))
          )
          .foregroundStyle(user.colorTheme.color(for: 4))
        }
      }
      .frame(height: 200)

      // Horizontal scrollable cards for top users
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          ForEach(sortedUsers.prefix(5), id: \.username) { user in
            VStack(spacing: 8) {
              CachedAvatarView(username: user.username, size: 44)
              Text(user.username)
                .font(.subheadline)
                .fontWeight(.medium)
              Text("\(weeklyContributions(for: user)) this week")
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
          }
        }
        .padding(.horizontal, 4)
      }
    }
  }

  // Helper to sum last 7 days' contributions
  private func weeklyContributions(for user: UserSettings) -> Int {
    guard let contributions = data[user.username] else { return 0 }
    return contributions.suffix(TimeFrame.week.days).reduce(0) { $0 + $1.contributionCount }
  }
}
