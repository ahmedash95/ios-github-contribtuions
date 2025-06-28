//
//  AppIntent.swift
//  Contribtuions Widget
//
//  Created by Ahmed on 28.06.25.
//

import AppIntents
import WidgetKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "Configuration" }
  static var description: IntentDescription {
    "Configure which GitHub user's contributions to display"
  }

  @Parameter(title: "Selected User", optionsProvider: UserOptionsProvider())
  var selectedUsername: String?

  @Parameter(title: "Display Mode", default: "single")
  var displayMode: String

  init() {
    self.selectedUsername = nil
    self.displayMode = "single"
  }

  init(selectedUsername: String?, displayMode: String = "single") {
    self.selectedUsername = selectedUsername
    self.displayMode = displayMode
  }
}

struct UserOptionsProvider: DynamicOptionsProvider {
  func results() async -> [String] {
    let dataManager = DataManager.shared
    let users = dataManager.getUsers()
    return users.map { $0.username }
  }

  func defaultResult() async -> String? {
    let dataManager = DataManager.shared
    let users = dataManager.getUsers()
    return users.first?.username
  }
}
