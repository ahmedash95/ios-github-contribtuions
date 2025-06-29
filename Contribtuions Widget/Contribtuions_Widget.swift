//
//  Contribtuions_Widget.swift
//  Contribtuions Widget
//
//  Created by Ahmed on 28.06.25.
//

import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> ContributionEntry {
    ContributionEntry(
      date: Date(), configuration: ConfigurationAppIntent(selectedUsernames: ["testuser"]),
      contributions: [], users: [])
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async
    -> ContributionEntry
  {
    let dataManager = DataManager.shared
    let users = dataManager.getUsers()

    print("🔍 Widget Snapshot - Users count: \(users.count)")

    // Get selected users based on widget family
    let selectedUsers =
      context.family == .systemSmall
      ? (configuration.selectedUsernames?.prefix(1).map { $0 } ?? [])
      : (configuration.selectedUsernames ?? [])

    print("🔍 Widget Snapshot - Selected users: \(selectedUsers)")

    var contributions: [ContributionDay] = []
    // For small widget or single user in medium widget, get contributions for the first selected user
    if let firstUsername = selectedUsers.first {
      contributions = dataManager.getCachedContributions(for: firstUsername) ?? []
      print("🔍 Widget Snapshot - Cached contributions count: \(contributions.count)")
    }

    return ContributionEntry(
      date: Date(), configuration: configuration, contributions: contributions, users: users)
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
    ContributionEntry
  > {
    let dataManager = DataManager.shared
    let users = dataManager.getUsers()

    print("🔍 Widget Timeline - Users count: \(users.count)")

    // Get selected users based on widget family
    let selectedUsers =
      context.family == .systemSmall
      ? (configuration.selectedUsernames?.prefix(1).map { $0 } ?? [])
      : (configuration.selectedUsernames ?? [])

    print("🔍 Widget Timeline - Selected users: \(selectedUsers)")

    var contributions: [ContributionDay] = []

    // Widget only uses cached data - no API calls
    // For small widget or single user in medium widget, get contributions for the first selected user
    if let firstUsername = selectedUsers.first {
      contributions = dataManager.getCachedContributions(for: firstUsername) ?? []
      print("🔍 Widget Timeline - Cached contributions count: \(contributions.count)")
    }

    let entry = ContributionEntry(
      date: Date(), configuration: configuration, contributions: contributions, users: users)

    // Refresh every hour
    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    return Timeline(entries: [entry], policy: .after(nextUpdate))
  }
}

struct ContributionEntry: TimelineEntry {
  let date: Date
  let configuration: ConfigurationAppIntent
  let contributions: [ContributionDay]
  let users: [UserSettings]
}

struct Contribtuions_WidgetEntryView: View {
  var entry: Provider.Entry
  @Environment(\.widgetFamily) var family
  private let dataManager = DataManager.shared

  var body: some View {
    if entry.users.isEmpty {
      emptyStateView
    } else {
      switch family {
      case .systemSmall:
        smallWidgetView
      case .systemMedium:
        mediumWidgetView
      default:
        smallWidgetView
      }
    }
  }

  private var emptyStateView: some View {
    VStack(spacing: 8) {
      Image(systemName: "chart.dots.scatter")
        .font(.system(size: 24))
        .foregroundColor(.secondary)

      Text("No Users")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var smallWidgetView: some View {
    Group {
      let username = entry.configuration.selectedUsernames?.first
      if username == nil || username?.isEmpty == true {
        noUserSelectedView
      } else if entry.contributions.isEmpty {
        noCachedDataView
      } else {
        singleUserChartView
      }
    }
  }

  private var mediumWidgetView: some View {
    Group {
      let selectedUsers = getSelectedUsers()

      if selectedUsers.isEmpty {
        noUserSelectedView
      } else if selectedUsers.count == 1 {
        // Single user - show full chart
        if entry.contributions.isEmpty {
          noCachedDataView
        } else {
          singleUserChartView
        }
      } else {
        // Multiple users - show list
        multipleUsersListView(users: selectedUsers)
      }
    }
  }

  private var noUserSelectedView: some View {
    VStack(spacing: 8) {
      Image(systemName: "person.crop.circle")
        .font(.system(size: 24))
        .foregroundColor(.secondary)

      Text("Select User")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var noCachedDataView: some View {
    VStack(spacing: 8) {
      Image(systemName: "clock.arrow.circlepath")
        .font(.system(size: 24))
        .foregroundColor(.secondary)

      Text("Loading...")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var singleUserChartView: some View {
    GeometryReader { geo in
      let (rowsCount, columnsCount): (Int, Int) = {
        switch family {
        case .systemSmall: return (7, 9)
        case .systemMedium: return (7, 20)
        default: return (7, 9)
        }
      }()
      ZStack(alignment: .topLeading) {
        // Chart fills the widget
        let selectedUsers = getSelectedUsers()
        if let firstUser = selectedUsers.first {
          WidgetContributionChartView(
            contributions: entry.contributions,
            userSettings: firstUser,
            size: geo.size,
            rowsCount: rowsCount,
            columnsCount: columnsCount
          )
          // .frame(width: geo.size.width, height: geo.size.height)
        }
        // Overlay: avatar + username
        HStack(spacing: 6) {
          if let firstUser = getSelectedUsers().first {
            CachedAvatarView(username: firstUser.username, size: 22)
            Text(firstUser.username)
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(.primary)
              .lineLimit(1)
              .truncationMode(.tail)
          }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemBackground).opacity(0.7))
            .shadow(color: Color.black.opacity(0.08), radius: 1, y: 1)
        )
        .padding(2)
      }
    }
  }

  private func multipleUsersListView(users: [UserSettings]) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(users.prefix(4), id: \.username) { user in
        UserWeekRow(user: user)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
  }

  private func getSelectedUsers() -> [UserSettings] {
    let usernames: [String] = {
      guard let selected = entry.configuration.selectedUsernames, !selected.isEmpty else {
        return []
      }
      switch family {
      case .systemSmall:
        return [selected.first!]
      default:
        return selected
      }
    }()
    return entry.users.filter { usernames.contains($0.username) }
  }
}

struct Contribtuions_Widget: Widget {
  let kind: String = "Contribtuions_Widget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) {
      entry in
      Contribtuions_WidgetEntryView(entry: entry)
        .padding(8)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .contentMarginsDisabled()
    .configurationDisplayName("GitHub Contributions")
    .description("Display your GitHub contribution graph")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview(as: .systemSmall) {
  Contribtuions_Widget()
} timeline: {
  ContributionEntry(
    date: .now,
    configuration: ConfigurationAppIntent(selectedUsernames: ["testuser"]),
    contributions: [], users: [])
}

#Preview(as: .systemMedium) {
  Contribtuions_Widget()
} timeline: {
  ContributionEntry(
    date: .now,
    configuration: ConfigurationAppIntent(selectedUsernames: ["user1", "user2"]),
    contributions: [], users: [])
}

// MARK: - User Week Row
struct UserWeekRow: View {
  let user: UserSettings
  private let dataManager = DataManager.shared
  @Environment(\.colorScheme) private var colorScheme

  private let boxSize: CGFloat = 20
  private let boxCornerRadius: CGFloat = 6
  private let boxSpacing: CGFloat = 3
  private let usernameWidth: CGFloat = 90

  var body: some View {
    HStack(alignment: .center, spacing: 4) {
      // Avatar + username tightly grouped
      HStack(spacing: 6) {
        CachedAvatarBoxView(
          username: user.username,
          size: boxSize,
          cornerRadius: boxCornerRadius,
          showBorder: true
        )
        Text(user.username)
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.primary)
          .lineLimit(1)
          .frame(width: usernameWidth, alignment: .leading)
      }
      Spacer(minLength: 8)
      if let contributions = dataManager.getCachedContributions(for: user.username) {
        let weekDays = last7Days(contributions: contributions)
        HStack(spacing: boxSpacing) {
          ForEach(weekDays, id: \.date) { day in
            RoundedRectangle(cornerRadius: boxCornerRadius)
              .fill(getColor(for: day.contributionCount))
              .frame(width: boxSize, height: boxSize)
              .overlay(
                RoundedRectangle(cornerRadius: boxCornerRadius)
                  .stroke(Color(.systemGray4), lineWidth: 1)
              )
              .shadow(color: Color.black.opacity(0.04), radius: 1, y: 1)
          }
        }
      } else {
        HStack(spacing: boxSpacing) {
          ForEach((0..<7).reversed(), id: \.self) { _ in
            RoundedRectangle(cornerRadius: boxCornerRadius)
              .fill(Color(.systemGray6))
              .frame(width: boxSize, height: boxSize)
              .overlay(
                RoundedRectangle(cornerRadius: boxCornerRadius)
                  .stroke(Color(.systemGray4), lineWidth: 1)
              )
              .shadow(color: Color.black.opacity(0.04), radius: 1, y: 1)
          }
        }
      }
    }
  }

  // Helper: Get last 7 days, oldest to newest
  private func last7Days(contributions: [ContributionDay]) -> [ContributionDay] {
    let sorted = contributions.sorted { ($0.date) < ($1.date) }
    return Array(sorted.suffix(7))
  }

  private func getColor(for count: Int) -> Color {
    let level = GitHubService.shared.getContributionLevel(count: count)
    return user.colorTheme.color(for: level, isDarkMode: colorScheme == .dark)
  }
}

// MARK: - Cached Avatar Box View
struct CachedAvatarBoxView: View {
  let username: String
  let size: CGFloat
  let cornerRadius: CGFloat
  var showBorder: Bool = false
  private let dataManager = DataManager.shared

  var body: some View {
    if let imageData = dataManager.getCachedAvatar(for: username),
      let uiImage = UIImage(data: imageData)
    {
      Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .if(showBorder) { view in
          view.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(Color(.systemGray4), lineWidth: 1)
          )
          .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)
        }
    } else {
      // Fallback to initials or placeholder
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(Color.gray.opacity(0.2))
        .overlay(
          Text(String(username.prefix(2)).uppercased())
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundColor(.gray)
        )
        .frame(width: size, height: size)
        .if(showBorder) { view in
          view.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(Color(.systemGray4), lineWidth: 1)
          )
          .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)
        }
    }
  }
}

// MARK: - View Modifier for Conditional
extension View {
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}
