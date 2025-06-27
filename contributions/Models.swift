import Combine
import Foundation
import SwiftUI

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

// MARK: - Existing Models
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

// GraphQL Response Models
struct GitHubGraphQLResponse: Codable {
  let data: GitHubData
}

struct GitHubData: Codable {
  let user: GitHubContributionUser?
}

struct GitHubContributionUser: Codable {
  let contributionsCollection: ContributionsCollection
}

struct ContributionsCollection: Codable {
  let contributionCalendar: ContributionCalendar
}

struct ContributionCalendar: Codable {
  let totalContributions: Int
  let weeks: [ContributionWeek]
}

struct ContributionWeek: Codable {
  let contributionDays: [GraphQLContributionDay]
}

struct GraphQLContributionDay: Codable {
  let contributionCount: Int
  let date: String
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

class UserStore: ObservableObject {
  @Published var users: [UserSettings] = []

  private let userDefaultsKey = "SavedUsers"

  init() {
    loadUsers()
  }

  func addUser(_ username: String, colorThemeId: String = "github") {
    let newUser = UserSettings(username: username, colorThemeId: colorThemeId)
    users.append(newUser)
    saveUsers()
  }

  func removeUser(_ username: String) {
    users.removeAll { $0.username == username }
    saveUsers()
  }

  func updateUserColor(_ username: String, colorThemeId: String) {
    if let index = users.firstIndex(where: { $0.username == username }) {
      users[index] = UserSettings(username: username, colorThemeId: colorThemeId)
      saveUsers()
    }
  }

  func updateUserOrder(_ newOrder: [UserSettings]) {
    users = newOrder
    saveUsers()
  }

  private func saveUsers() {
    if let data = try? JSONEncoder().encode(users) {
      UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
  }

  private func loadUsers() {
    if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
      let savedUsers = try? JSONDecoder().decode([UserSettings].self, from: data)
    {
      users = savedUsers
    }
  }
}
