import SwiftUI
import Charts

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
                ForEach(sortedUsers.prefix(5), id: \..username) { user in
                    BarMark(
                        x: .value("User", user.username),
                        y: .value("Streak", streak(for: user))
                    )
                    .foregroundStyle(user.colorTheme.color(for: 4))
                }
            }
            .frame(height: 200)
        }
    }
}
