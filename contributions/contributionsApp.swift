//
//  contributionsApp.swift
//  contributions
//
//  Created by Ahmed on 27.06.25.
//

import SwiftUI
import WidgetKit

@main
struct contributionsApp: App {
  @StateObject private var userStore = UserStore()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(userStore)
        .onAppear {
          WidgetCenter.shared.reloadAllTimelines()
          preloadAvatarsForExistingUsers()
          // Trigger background refresh when app becomes active
          userStore.refreshAllUsersData()
        }
        .onReceive(
          NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        ) { _ in
          // Refresh data when app becomes active
          userStore.refreshAllUsersData()
        }
    }
  }

  private func preloadAvatarsForExistingUsers() {
    let dataManager = DataManager.shared
    let users = dataManager.getUsers()

    for user in users {
      // Check if we already have cached avatar data
      if dataManager.getCachedAvatar(for: user.username) == nil {
        // Try to fetch and cache avatar
        Task {
          do {
            let githubUser = try await GitHubService.shared.fetchUser(username: user.username)
            if let avatarUrl = URL(string: githubUser.avatarUrl) {
              let (imageData, _) = try await URLSession.shared.data(from: avatarUrl)
              dataManager.cacheAvatar(imageData, for: user.username)
              print("✅ Main App - Preloaded avatar for \(user.username)")
            }
          } catch {
            print("❌ Main App - Failed to preload avatar for \(user.username): \(error)")
          }
        }
      }
    }
  }
}

struct ContributionWidgetBundle: WidgetBundle {
  var body: some Widget {
    ContributionWidget()
  }
}
