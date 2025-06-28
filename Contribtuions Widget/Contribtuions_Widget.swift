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
      date: Date(), configuration: ConfigurationAppIntent(), contributions: [], users: [])
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async
    -> ContributionEntry
  {
    let dataManager = DataManager.shared
    let users = dataManager.getUsers()

    print("🔍 Widget Snapshot - Users count: \(users.count)")
    print("🔍 Widget Snapshot - Selected username: \(configuration.selectedUsername ?? "nil")")

    var contributions: [ContributionDay] = []
    if let username = configuration.selectedUsername, !username.isEmpty {
      contributions = dataManager.getCachedContributions(for: username) ?? []
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
    print("🔍 Widget Timeline - Selected username: \(configuration.selectedUsername ?? "nil")")

    var contributions: [ContributionDay] = []

    // Widget only uses cached data - no API calls
    if let username = configuration.selectedUsername, !username.isEmpty {
      contributions = dataManager.getCachedContributions(for: username) ?? []
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
    } else if entry.configuration.selectedUsername == nil
      || entry.configuration.selectedUsername?.isEmpty == true
    {
      noUserSelectedView
    } else if entry.contributions.isEmpty {
      noCachedDataView
    } else {
      contributionView
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
      Image(systemName: "arrow.up.circle")
        .font(.system(size: 24))
        .foregroundColor(.secondary)

      Text("Open app to load data")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var contributionView: some View {
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
        if let username = entry.configuration.selectedUsername,
          let user = entry.users.first(where: { $0.username == username })
        {
          WidgetContributionChartView(
            contributions: entry.contributions,
            userSettings: user,
            size: geo.size,
            rowsCount: rowsCount,
            columnsCount: columnsCount
          )
          .frame(width: geo.size.width, height: geo.size.height)
        }
        // Overlay: avatar + username
        HStack(spacing: 6) {
          if let username = entry.configuration.selectedUsername {
            CachedAvatarView(username: username, size: 22)
          }
          Text(entry.configuration.selectedUsername ?? "")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.primary)
            .lineLimit(1)
            .truncationMode(.tail)
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
}

struct Contribtuions_Widget: Widget {
  let kind: String = "Contribtuions_Widget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) {
      entry in
      Contribtuions_WidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("GitHub Contributions")
    .description("Display your GitHub contribution graph")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview(as: .systemSmall) {
  Contribtuions_Widget()
} timeline: {
  ContributionEntry(
    date: .now, configuration: ConfigurationAppIntent(selectedUsername: "testuser"),
    contributions: [], users: [])
}
