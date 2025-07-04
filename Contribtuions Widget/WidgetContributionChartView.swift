//
//  WidgetContributionChartView.swift
//  Contribtuions Widget
//
//  Created by Ahmed on 28.06.25.
//

import SwiftUI

struct WidgetContributionChartView: View {
  let contributions: [ContributionDay]
  let userSettings: UserSettings
  var size: CGSize
  let rowsCount: Int
  let columnsCount: Int
  @Environment(\.colorScheme) private var colorScheme

  let tileSpacing: CGFloat = 1

  var body: some View {
    // Only show the most recent rowsCount * columnsCount days
    let daysToShow = rowsCount * columnsCount
    let days = Array(contributions.suffix(daysToShow))

    // Arrange into columns (weeks) - each column represents a week
    // The last day should be in the bottom right corner (last row of last column)
    let columns = stride(from: 0, to: days.count, by: rowsCount).map {
      Array(days[$0..<min($0 + rowsCount, days.count)])
    }

    // Calculate tile size
    let tileSize =
      (size.width - CGFloat(columnsCount - 1) * tileSpacing - 2) / CGFloat(columnsCount)

    HStack(spacing: tileSpacing) {
      ForEach(0..<columnsCount, id: \.self) { col in
        VStack(spacing: tileSpacing) {
          ForEach(0..<rowsCount, id: \.self) { row in
            if col < columns.count && row < columns[col].count {
              let day = columns[col][row]
              RoundedRectangle(cornerRadius: 2)
                .fill(getColor(for: day.contributionCount))
                .frame(width: tileSize, height: tileSize)
                .shadow(color: Color.black.opacity(0.08), radius: 1, y: 1)
            } else {
              RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray6))
                .frame(width: tileSize, height: tileSize)
                .shadow(color: Color.black.opacity(0.08), radius: 1, y: 1)
            }
          }
        }
      }
    }
    .frame(width: size.width, height: size.height, alignment: .center)
  }

  private func getColor(for count: Int) -> Color {
    let level = GitHubService.shared.getContributionLevel(count: count)
    return userSettings.colorTheme.color(for: level, isDarkMode: colorScheme == .dark)
  }
}
