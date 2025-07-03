//
//  SharedModels.swift
//  Contribtuions Widget
//
//  Created by Ahmed on 28.06.25.
//

import Combine
import Foundation
import SwiftUI

// MARK: - GitHub API Models
struct GitHubUser: Codable, Identifiable {
  let id: Int
  let login: String
  let avatarUrl: String
  let name: String?

  enum CodingKeys: String, CodingKey {
    case id, login, name
    case avatarUrl = "avatar_url"
  }
}

// MARK: - Shared Models for App and Widget
struct ContributionDay: Codable, Identifiable, Equatable {
  let id = UUID()
  let date: String
  let contributionCount: Int
  let color: String

  enum CodingKeys: String, CodingKey {
    case date, contributionCount, color
  }

  static func == (lhs: ContributionDay, rhs: ContributionDay) -> Bool {
    return lhs.date == rhs.date && lhs.contributionCount == rhs.contributionCount
  }
}

struct UserSettings: Codable, Identifiable {
  let username: String
  let colorThemeId: String
  let id: UUID

  init(username: String, colorThemeId: String = "github") {
    self.username = username
    self.colorThemeId = colorThemeId
    self.id = UUID()
  }

  var colorTheme: ContributionColorTheme {
    return ContributionColorTheme.theme(for: colorThemeId)
  }
}

// MARK: - Color System
struct ContributionColorTheme: Codable, Identifiable {
  let id: String
  let name: String
  let lightColors: [String]  // Hex colors for levels 0-4 in light mode
  let darkColors: [String]  // Hex colors for levels 0-4 in dark mode

  static let themes: [ContributionColorTheme] = [
    ContributionColorTheme(
      id: "github",
      name: "GitHub Green",
      lightColors: ["#ebedf0", "#9be9a8", "#40c463", "#30a14e", "#216e39"],
      darkColors: ["#161b22", "#0e4429", "#006d32", "#26a641", "#39d353"]
    ),
    ContributionColorTheme(
      id: "blue",
      name: "Ocean Blue",
      lightColors: ["#ebedf0", "#b3d9ff", "#66b3ff", "#3399ff", "#0066cc"],
      darkColors: ["#161b22", "#0c2d6b", "#1f6feb", "#388bfd", "#58a6ff"]
    ),
    ContributionColorTheme(
      id: "purple",
      name: "Royal Purple",
      lightColors: ["#ebedf0", "#d4b3ff", "#b366ff", "#9933ff", "#6600cc"],
      darkColors: ["#161b22", "#352160", "#5a32a3", "#7c3aed", "#a855f7"]
    ),
    ContributionColorTheme(
      id: "orange",
      name: "Sunset Orange",
      lightColors: ["#ebedf0", "#ffcc99", "#ff9933", "#ff6600", "#cc3300"],
      darkColors: ["#161b22", "#7c2d12", "#c2410c", "#ea580c", "#f97316"]
    ),
    ContributionColorTheme(
      id: "red",
      name: "Crimson Red",
      lightColors: ["#ebedf0", "#ffb3b3", "#ff6666", "#ff3333", "#cc0000"],
      darkColors: ["#161b22", "#7c2d12", "#c2410c", "#dc2626", "#ef4444"]
    ),
    ContributionColorTheme(
      id: "teal",
      name: "Teal",
      lightColors: ["#ebedf0", "#99e6e6", "#66cccc", "#33b3b3", "#009999"],
      darkColors: ["#161b22", "#134e4a", "#0f766e", "#14b8a6", "#2dd4bf"]
    ),
    ContributionColorTheme(
      id: "pink",
      name: "Rose Pink",
      lightColors: ["#ebedf0", "#ffb3d9", "#ff66b3", "#ff3380", "#cc004d"],
      darkColors: ["#161b22", "#831843", "#be185d", "#ec4899", "#f472b6"]
    ),
    ContributionColorTheme(
      id: "yellow",
      name: "Golden Yellow",
      lightColors: ["#ebedf0", "#fff2cc", "#ffe680", "#ffd633", "#ccaa00"],
      darkColors: ["#161b22", "#713f12", "#a16207", "#ca8a04", "#eab308"]
    ),
    ContributionColorTheme(
      id: "indigo",
      name: "Deep Indigo",
      lightColors: ["#ebedf0", "#c7d2fe", "#a5b4fc", "#818cf8", "#6366f1"],
      darkColors: ["#161b22", "#312e81", "#3730a3", "#4338ca", "#6366f1"]
    ),
    ContributionColorTheme(
      id: "emerald",
      name: "Emerald Green",
      lightColors: ["#ebedf0", "#a7f3d0", "#6ee7b7", "#34d399", "#10b981"],
      darkColors: ["#161b22", "#064e3b", "#065f46", "#047857", "#059669"]
    ),
    ContributionColorTheme(
      id: "amber",
      name: "Warm Amber",
      lightColors: ["#ebedf0", "#fde68a", "#fbbf24", "#f59e0b", "#d97706"],
      darkColors: ["#161b22", "#78350f", "#92400e", "#b45309", "#d97706"]
    ),
    ContributionColorTheme(
      id: "rose",
      name: "Soft Rose",
      lightColors: ["#ebedf0", "#fecdd3", "#fda4af", "#fb7185", "#f43f5e"],
      darkColors: ["#161b22", "#881337", "#be123c", "#e11d48", "#f43f5e"]
    ),
    ContributionColorTheme(
      id: "slate",
      name: "Cool Slate",
      lightColors: ["#ebedf0", "#cbd5e1", "#94a3b8", "#64748b", "#475569"],
      darkColors: ["#161b22", "#334155", "#475569", "#64748b", "#94a3b8"]
    ),
  ]

  static func theme(for id: String) -> ContributionColorTheme {
    return themes.first { $0.id == id } ?? themes[0]
  }

  func color(for level: Int, isDarkMode: Bool = false) -> Color {
    guard level >= 0 && level < lightColors.count else {
      return Color(.systemGray6)
    }

    // For level 0 (empty boxes), use a consistent gray color
    if level == 0 {
      return isDarkMode ? Color(.systemGray5) : Color(.systemGray5)
    }

    let hexColor = isDarkMode ? darkColors[level] : lightColors[level]
    return Color(hex: hexColor)
  }
}

// MARK: - Color Extension
extension Color {
  init(hex: String, isDarkMode: Bool = false) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}

// MARK: - Caching System
struct CachedContributionData: Codable {
  let username: String
  let contributions: [ContributionDay]
  let timestamp: Date
  var lastRefreshAttempt: Date

  init(username: String, contributions: [ContributionDay]) {
    self.username = username
    self.contributions = contributions
    self.timestamp = Date()
    self.lastRefreshAttempt = Date()
  }

  // Check if we should attempt to refresh (every hour)
  var shouldRefresh: Bool {
    let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
    return lastRefreshAttempt < oneHourAgo
  }

  // Update the refresh attempt timestamp without changing the data
  mutating func markRefreshAttempt() {
    self.lastRefreshAttempt = Date()
  }
}

struct CachedUserData: Codable {
  let username: String
  let user: GitHubUser
  let timestamp: Date
  var lastRefreshAttempt: Date

  init(username: String, user: GitHubUser) {
    self.username = username
    self.user = user
    self.timestamp = Date()
    self.lastRefreshAttempt = Date()
  }

  // Check if we should attempt to refresh (every 24 hours for user data)
  var shouldRefresh: Bool {
    let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    return lastRefreshAttempt < oneDayAgo
  }

  // Update the refresh attempt timestamp without changing the data
  mutating func markRefreshAttempt() {
    self.lastRefreshAttempt = Date()
  }
}

struct CachedAvatarData: Codable {
  let username: String
  let imageData: Data
  let timestamp: Date
  var lastRefreshAttempt: Date

  init(username: String, imageData: Data) {
    self.username = username
    self.imageData = imageData
    self.timestamp = Date()
    self.lastRefreshAttempt = Date()
  }

  // Check if we should attempt to refresh (every 7 days for avatars)
  var shouldRefresh: Bool {
    let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    return lastRefreshAttempt < oneWeekAgo
  }

  // Update the refresh attempt timestamp without changing the data
  mutating func markRefreshAttempt() {
    self.lastRefreshAttempt = Date()
  }
}

// MARK: - Shared Data Manager
class DataManager: ObservableObject {
  static let shared = DataManager()

  private let sharedDefaults: UserDefaults?
  private let cacheKey = "CachedContributions"
  private let userCacheKey = "CachedUsers"
  private let avatarCacheKey = "CachedAvatars"
  private let usersKey = "SavedUsers"

  private init() {
    self.sharedDefaults = UserDefaults(suiteName: "group.com.contributions.app")
  }

  // MARK: - User Management
  func getUsers() -> [UserSettings] {
    guard let sharedDefaults = sharedDefaults else {
      print("❌ DataManager - No shared defaults available")
      return []
    }

    guard let data = sharedDefaults.data(forKey: usersKey) else {
      print("❌ DataManager - No user data found in shared defaults")
      return []
    }

    guard let users = try? JSONDecoder().decode([UserSettings].self, from: data) else {
      print("❌ DataManager - Failed to decode user data")
      return []
    }

    print("✅ DataManager - Successfully loaded \(users.count) users")
    return users
  }

  func saveUsers(_ users: [UserSettings]) {
    guard let sharedDefaults = sharedDefaults,
      let data = try? JSONEncoder().encode(users)
    else { return }

    sharedDefaults.set(data, forKey: usersKey)
    UserDefaults.standard.set(data, forKey: usersKey)
  }

  // MARK: - User Caching
  func getCachedUser(for username: String) -> GitHubUser? {
    guard let sharedDefaults = sharedDefaults,
      let data = sharedDefaults.data(forKey: "\(userCacheKey)_\(username)"),
      let cachedData = try? JSONDecoder().decode(CachedUserData.self, from: data)
    else {
      return nil
    }
    return cachedData.user
  }

  func shouldRefreshUser(for username: String) -> Bool {
    guard let sharedDefaults = sharedDefaults,
      let data = sharedDefaults.data(forKey: "\(userCacheKey)_\(username)"),
      let cachedData = try? JSONDecoder().decode(CachedUserData.self, from: data)
    else {
      return true  // No cached data, should refresh
    }
    return cachedData.shouldRefresh
  }

  func cacheUser(_ user: GitHubUser, for username: String) {
    guard let sharedDefaults = sharedDefaults else { return }

    let cachedData = CachedUserData(username: username, user: user)
    if let data = try? JSONEncoder().encode(cachedData) {
      sharedDefaults.set(data, forKey: "\(userCacheKey)_\(username)")
    }
  }

  func markUserRefreshAttempt(for username: String) {
    guard let sharedDefaults = sharedDefaults,
      let data = sharedDefaults.data(forKey: "\(userCacheKey)_\(username)"),
      var cachedData = try? JSONDecoder().decode(CachedUserData.self, from: data)
    else {
      return
    }

    cachedData.markRefreshAttempt()
    if let updatedData = try? JSONEncoder().encode(cachedData) {
      sharedDefaults.set(updatedData, forKey: "\(userCacheKey)_\(username)")
    }
  }

  // MARK: - Avatar Caching
  func getCachedAvatar(for username: String) -> Data? {
    guard let sharedDefaults = sharedDefaults,
      let data = sharedDefaults.data(forKey: "\(avatarCacheKey)_\(username)"),
      let cachedData = try? JSONDecoder().decode(CachedAvatarData.self, from: data)
    else {
      return nil
    }
    return cachedData.imageData
  }

  func shouldRefreshAvatar(for username: String) -> Bool {
    guard let sharedDefaults = sharedDefaults,
      let data = sharedDefaults.data(forKey: "\(avatarCacheKey)_\(username)"),
      let cachedData = try? JSONDecoder().decode(CachedAvatarData.self, from: data)
    else {
      return true  // No cached data, should refresh
    }
    return cachedData.shouldRefresh
  }

  func cacheAvatar(_ imageData: Data, for username: String) {
    guard let sharedDefaults = sharedDefaults else { return }

    let cachedData = CachedAvatarData(username: username, imageData: imageData)
    if let data = try? JSONEncoder().encode(cachedData) {
      sharedDefaults.set(data, forKey: "\(avatarCacheKey)_\(username)")
      print("✅ DataManager - Cached avatar image data for \(username)")
    }
  }

  func markAvatarRefreshAttempt(for username: String) {
    guard let sharedDefaults = sharedDefaults,
      let data = sharedDefaults.data(forKey: "\(avatarCacheKey)_\(username)"),
      var cachedData = try? JSONDecoder().decode(CachedAvatarData.self, from: data)
    else {
      return
    }

    cachedData.markRefreshAttempt()
    if let updatedData = try? JSONEncoder().encode(cachedData) {
      sharedDefaults.set(updatedData, forKey: "\(avatarCacheKey)_\(username)")
    }
  }

  // MARK: - Contribution Caching
  func getCachedContributions(for username: String) -> [ContributionDay]? {
    guard let sharedDefaults = sharedDefaults else {
      print("❌ DataManager - No shared defaults for contributions")
      return nil
    }

    guard let data = sharedDefaults.data(forKey: "\(cacheKey)_\(username)") else {
      print("❌ DataManager - No cached contributions for \(username)")
      return nil
    }

    guard let cachedData = try? JSONDecoder().decode(CachedContributionData.self, from: data) else {
      print("❌ DataManager - Failed to decode cached contributions for \(username)")
      return nil
    }

    print(
      "✅ DataManager - Successfully loaded \(cachedData.contributions.count) contributions for \(username)"
    )
    return cachedData.contributions
  }

  func shouldRefreshContributions(for username: String) -> Bool {
    guard let sharedDefaults = sharedDefaults,
      let data = sharedDefaults.data(forKey: "\(cacheKey)_\(username)"),
      let cachedData = try? JSONDecoder().decode(CachedContributionData.self, from: data)
    else {
      return true  // No cached data, should refresh
    }
    return cachedData.shouldRefresh
  }

  func cacheContributions(_ contributions: [ContributionDay], for username: String) {
    guard let sharedDefaults = sharedDefaults else { return }

    let cachedData = CachedContributionData(username: username, contributions: contributions)
    if let data = try? JSONEncoder().encode(cachedData) {
      sharedDefaults.set(data, forKey: "\(cacheKey)_\(username)")
    }
  }

  func markContributionsRefreshAttempt(for username: String) {
    guard let sharedDefaults = sharedDefaults,
      let data = sharedDefaults.data(forKey: "\(cacheKey)_\(username)"),
      var cachedData = try? JSONDecoder().decode(CachedContributionData.self, from: data)
    else {
      return
    }

    cachedData.markRefreshAttempt()
    if let updatedData = try? JSONEncoder().encode(cachedData) {
      sharedDefaults.set(updatedData, forKey: "\(cacheKey)_\(username)")
    }
  }

  func clearCache(for username: String? = nil) {
    guard let sharedDefaults = sharedDefaults else { return }

    if let username = username {
      sharedDefaults.removeObject(forKey: "\(cacheKey)_\(username)")
      sharedDefaults.removeObject(forKey: "\(userCacheKey)_\(username)")
      sharedDefaults.removeObject(forKey: "\(avatarCacheKey)_\(username)")
    } else {
      // Clear all cached data
      let keys = sharedDefaults.dictionaryRepresentation().keys.filter {
        $0.hasPrefix(cacheKey) || $0.hasPrefix(userCacheKey) || $0.hasPrefix(avatarCacheKey)
      }
      keys.forEach { sharedDefaults.removeObject(forKey: $0) }
    }
  }
}

// MARK: - GitHub Service (Simplified for Widget)
class GitHubService {
  static let shared = GitHubService()

  private let dataManager = DataManager.shared

  private init() {}

  func getContributionLevel(count: Int) -> Int {
    switch count {
    case 0: return 0
    case 1...3: return 1
    case 4...6: return 2
    case 7...9: return 3
    default: return 4
    }
  }

  // Simplified fetch method for widget - only uses cached data
  func fetchContributions(username: String, days: Int = 91, useCache: Bool = true) async throws
    -> [ContributionDay]
  {
    // For widget, we only use cached data to avoid API calls
    if let cachedContributions = dataManager.getCachedContributions(for: username) {
      return Array(cachedContributions.suffix(days))
    }

    // If no cached data, return empty array
    return []
  }
}

// MARK: - Cached Avatar View
struct CachedAvatarView: View {
  let username: String
  let size: CGFloat
  private let dataManager = DataManager.shared

  var body: some View {
    if let imageData = dataManager.getCachedAvatar(for: username),
      let uiImage = UIImage(data: imageData)
    {
      Image(uiImage: uiImage)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
    } else {
      // Fallback to initials or placeholder
      Circle()
        .fill(Color.gray.opacity(0.2))
        .overlay(
          Text(String(username.prefix(2)).uppercased())
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundColor(.gray)
        )
        .frame(width: size, height: size)
        .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
    }
  }
}
