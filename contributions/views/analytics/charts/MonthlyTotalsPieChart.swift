import SwiftUI
import Charts

struct MonthlyTotalsPieChart: View {
    let users: [UserSettings]
    let data: [String: [ContributionDay]]

    private func total(for user: UserSettings) -> Int {
        guard let contribs = data[user.username] else { return 0 }
        let recent = contribs.suffix(30)
        return recent.reduce(0) { $0 + $1.contributionCount }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Monthly Totals")
                .font(.headline)
            Chart {
                ForEach(users, id: \..username) { user in
                    SectorMark(
                        angle: .value("Total", total(for: user))
                    )
                    .foregroundStyle(by: .value("User", user.username))
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
