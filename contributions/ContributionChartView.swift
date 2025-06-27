import Combine
import SwiftUI

struct ContributionChartView: View {
  let contributions: [ContributionDay]
  let customColor: Color
  let compact: Bool

  @State private var selectedDay: ContributionDay?
  @State private var showingDetail = false
  @State private var scrollPosition: Int? = nil

  init(contributions: [ContributionDay], customColor: Color = .green, compact: Bool = false) {
    self.contributions = contributions
    self.customColor = customColor
    self.compact = compact
  }

  var body: some View {
    if compact {
      compactChart
    } else {
      regularChart
    }
  }

  private var compactChart: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 2) {
        ForEach(Array(githubStyleWeeks(last91Days).enumerated()), id: \.offset) { weekIndex, week in
          VStack(spacing: 2) {
            ForEach(0..<7, id: \.self) { dayIndex in
              if dayIndex < week.count {
                let day = week[dayIndex]
                RoundedRectangle(cornerRadius: 2)
                  .fill(getColor(for: day.contributionCount))
                  .frame(width: 10, height: 10)
                  .onTapGesture {
                    selectedDay = day
                    showingDetail = true
                  }
              } else {
                RoundedRectangle(cornerRadius: 2)
                  .fill(Color(.systemGray6))
                  .frame(width: 10, height: 10)
              }
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      HStack {
        Text("\(totalContributions(last91Days)) contributions")
          .font(.caption2)
          .foregroundColor(.secondary)
        Spacer()
        legendView
      }
    }
    .alert("Contribution Details", isPresented: $showingDetail) {
      Button("OK") {}
    } message: {
      if let day = selectedDay {
        Text("\(day.contributionCount) contributions on \(formatDate(day.date))")
      }
    }
  }

  private var regularChart: some View {
    VStack(alignment: .leading, spacing: 8) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 2) {
          ForEach(Array(githubStyleWeeks(last364Days).enumerated()), id: \.offset) {
            weekIndex, week in
            VStack(spacing: 2) {
              ForEach(0..<7, id: \.self) { dayIndex in
                if dayIndex < week.count {
                  let day = week[dayIndex]
                  RoundedRectangle(cornerRadius: 2)
                    .fill(getColor(for: day.contributionCount))
                    .frame(width: 11, height: 11)
                    .onTapGesture {
                      selectedDay = day
                      showingDetail = true
                    }
                } else {
                  RoundedRectangle(cornerRadius: 2)
                    .fill(Color.clear)
                    .frame(width: 11, height: 11)
                }
              }
            }
            .id(weekIndex)
          }
        }
      }
      .scrollPosition(id: $scrollPosition)
      .onAppear {
        // Scroll to the end to show latest days
        let totalWeeks = githubStyleWeeks(last364Days).count
        if totalWeeks > 0 {
          scrollPosition = totalWeeks - 1
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      HStack {
        Text("\(totalContributions(last364Days)) contributions in the last year")
          .font(.caption2)
          .foregroundColor(.secondary)
        Spacer()
        legendView
      }
    }
    .alert("Contribution Details", isPresented: $showingDetail) {
      Button("OK") {}
    } message: {
      if let day = selectedDay {
        Text("\(day.contributionCount) contributions on \(formatDate(day.date))")
      }
    }
  }

  private var legendView: some View {
    HStack(spacing: 2) {
      Text("Less")
        .font(.caption2)
        .foregroundColor(.secondary)

      ForEach(0..<5) { level in
        RoundedRectangle(cornerRadius: 1)
          .fill(
            level == 0 ? Color(.systemGray6) : customColor.opacity(max(0.6, Double(level) * 0.25))
          )
          .frame(width: 8, height: 8)
      }

      Text("More")
        .font(.caption2)
        .foregroundColor(.secondary)
    }
  }

  private func formatDate(_ dateString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    guard let date = formatter.date(from: dateString) else { return dateString }

    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: date)
  }

  private func githubStyleWeeks(_ contributions: [ContributionDay]) -> [[ContributionDay]] {
    var weeks: [[ContributionDay]] = []
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    // Group contributions by actual calendar weeks (Sunday to Saturday)
    var currentWeek: [ContributionDay] = []

    for contribution in contributions {
      guard let date = dateFormatter.date(from: contribution.date) else { continue }
      let weekday = calendar.component(.weekday, from: date)  // 1 = Sunday, 7 = Saturday

      // Fill empty days at the start of the first week
      if currentWeek.isEmpty && weekday > 1 {
        // Add empty days for the beginning of the week
        for _ in 1..<weekday {
          // Don't add empty contributions, just skip
        }
      }

      currentWeek.append(contribution)

      // End of week (Saturday) or last contribution
      if weekday == 7 || contribution == contributions.last {
        weeks.append(currentWeek)
        currentWeek = []
      }
    }

    // Add the last week if it has content
    if !currentWeek.isEmpty {
      weeks.append(currentWeek)
    }

    return weeks
  }

  private func monthLabel(for weekIndex: Int, weeks: [[ContributionDay]]) -> String {
    let months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ]

    guard weekIndex < weeks.count,
      let firstDay = weeks[weekIndex].first
    else { return "" }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    guard let date = dateFormatter.date(from: firstDay.date) else { return "" }

    let monthIndex = Calendar.current.component(.month, from: date) - 1
    return months[min(max(monthIndex, 0), 11)]
  }

  private func totalContributions(_ contributions: [ContributionDay]) -> Int {
    contributions.reduce(0) { $0 + $1.contributionCount }
  }

  private var last91Days: [ContributionDay] {
    Array(contributions.suffix(91))  // ~13 weeks
  }

  private var last364Days: [ContributionDay] {
    Array(contributions.suffix(364))  // ~52 weeks
  }

  private func getColor(for count: Int) -> Color {
    let intensity = GitHubService.shared.getContributionIntensity(count: count)
    if intensity == 0.0 {
      return Color(.systemGray6)
    } else {
      return customColor.opacity(max(0.6, intensity))
    }
  }
}
