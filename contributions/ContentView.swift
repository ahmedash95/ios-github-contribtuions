//
//  ContentView.swift
//  contributions
//
//  Created by Ahmed on 27.06.25.
//

import Combine
import SwiftUI
import WidgetKit

struct ContentView: View {
  @EnvironmentObject var userStore: UserStore
  @State private var showingAddUser = false
  @State private var showingSettings = false
  @State private var showingTokenSetup = false
  @State private var needsTokenSetup = !GitHubService.shared.isTokenConfigured()
  @State private var isRefreshing = false

  var body: some View {
    NavigationStack {
      ScrollView {
        if needsTokenSetup {
          tokenSetupPrompt
        } else if userStore.users.isEmpty {
          emptyState
        } else {
          LazyVGrid(
            columns: [
              GridItem(.adaptive(minimum: 300, maximum: .infinity), spacing: 12)
            ],
            spacing: 12
          ) {
            ForEach(userStore.users, id: \.username) { userSettings in
              UserContributionView(userSettings: userSettings, forceRefresh: isRefreshing)
                .contextMenu {
                  Button("Remove User", role: .destructive) {
                    userStore.removeUser(userSettings.username)
                  }
                }
            }
          }
          .padding(12)
        }
      }
      .refreshable {
        await refreshAllData()
      }
      .background(Color(.systemGroupedBackground).ignoresSafeArea())
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            showingSettings = true
          } label: {
            Image(systemName: "gearshape")
          }
        }

        ToolbarItem(placement: .primaryAction) {
          Button {
            if needsTokenSetup {
              showingTokenSetup = true
            } else {
              showingAddUser = true
            }
          } label: {
            Image(systemName: needsTokenSetup ? "key" : "plus")
          }
        }
      }
      .sheet(isPresented: $showingAddUser) {
        AddUserView(userStore: userStore)
      }
      .sheet(isPresented: $showingSettings) {
        SettingsView(userStore: userStore)
      }
      .sheet(isPresented: $showingTokenSetup) {
        GitHubTokenSetupView()
          .onDisappear {
            needsTokenSetup = !GitHubService.shared.isTokenConfigured()
          }
      }
      .onAppear {
        // Test App Groups functionality
        DataManager.shared.testAppGroupsAccess()
      }
    }
  }

  private func refreshAllData() async {
    isRefreshing = true

    // Clear all cache to force fresh data fetch
    DataManager.shared.clearCache()

    // Refresh all users data
    await userStore.refreshAllUsersDataAsync()

    // Reload widget timelines
    WidgetCenter.shared.reloadAllTimelines()

    isRefreshing = false
  }

  private var tokenSetupPrompt: some View {
    VStack(spacing: 20) {
      Image(systemName: "key.fill")
        .font(.system(size: 50))
        .foregroundColor(.blue)

      VStack(spacing: 8) {
        Text("GitHub Token Required")
          .font(.title2)
          .fontWeight(.semibold)

        Text(
          "To display contribution data, we need a GitHub Personal Access Token with read permissions."
        )
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
      }

      Button {
        showingTokenSetup = true
      } label: {
        Label("Setup GitHub Token", systemImage: "key")
          .font(.headline)
          .foregroundColor(.white)
          .padding()
          .background(Color.blue)
          .cornerRadius(10)
      }

      Button {
        if let url = URL(string: "https://github.com/settings/tokens") {
          UIApplication.shared.open(url)
        }
      } label: {
        HStack {
          Image(systemName: "safari")
          Text("Open GitHub Tokens Page")
        }
        .font(.subheadline)
        .foregroundColor(.blue)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }

  private var emptyState: some View {
    VStack(spacing: 20) {
      Image(systemName: "chart.dots.scatter")
        .font(.system(size: 60))
        .foregroundColor(.secondary)

      VStack(spacing: 8) {
        Text("No Users Added")
          .font(.title2)
          .fontWeight(.semibold)

        Text("Add a GitHub username to view their contribution chart")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }

      Button {
        showingAddUser = true
      } label: {
        Label("Add User", systemImage: "plus")
          .font(.headline)
          .foregroundColor(.white)
          .padding()
          .background(Color.blue)
          .cornerRadius(10)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}

#Preview {
  ContentView()
}
