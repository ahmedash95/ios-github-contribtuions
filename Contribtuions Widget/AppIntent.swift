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
    "Select one or more GitHub users. Small widget shows the first selected user; medium widget shows all selected users."
  }

  @Parameter(title: "Selected Users", optionsProvider: UserOptionsProvider())
  var selectedUsernames: [String]?

  init() {
    self.selectedUsernames = nil
  }

  init(selectedUsernames: [String]? = nil) {
    self.selectedUsernames = selectedUsernames
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
