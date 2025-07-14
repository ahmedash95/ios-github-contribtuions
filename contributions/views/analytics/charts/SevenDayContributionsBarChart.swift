import SwiftUI
import Charts

struct SevenDayContributionsBarChart: View {
    let users: [UserSettings]
    let data: [String: [ContributionDay]]

    private var last7Dates: [String] {
        if let first = data.values.first, let lastDateStr = first.last?.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let lastDate = formatter.date(from: lastDateStr) else { return [] }
            return (0..<7).reversed().compactMap { offset in
                let date = Calendar.current.date(byAdding: .day, value: -offset, to: lastDate)
                return date.map { formatter.string(from: $0) }
            }
        }
        return []
    }

    private func count(for user: UserSettings, date: String) -> Int {
        data[user.username]?.first(where: { $0.date == date })?.contributionCount ?? 0
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Last 7 Days")
                .font(.headline)
            Chart {
                ForEach(last7Dates, id: \..self) { day in
                    ForEach(users, id: \..username) { user in
                        BarMark(
                            x: .value("Day", day),
                            y: .value("Contributions", count(for: user, date: day))
                        )
                        .foregroundStyle(by: .value("User", user.username))
                    }
                }
            }
            .chartForegroundStyleScale(
                domain: users.map { $0.username },
                range: users.map { $0.colorTheme.color(for: 4) }
            )
            .frame(height: 200)
        }
    }
}
