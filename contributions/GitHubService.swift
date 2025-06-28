import Combine
import Foundation

class GitHubService: ObservableObject {
  static let shared = GitHubService()

  private let baseURL = "https://api.github.com"
  private let graphQLURL = "https://api.github.com/graphql"
  private let dataManager = DataManager.shared

  private var githubToken: String {
    return KeychainHelper.shared.load() ?? ""
  }

  private var hasValidToken: Bool {
    return !githubToken.isEmpty
  }

  func saveToken(_ token: String) -> Bool {
    return KeychainHelper.shared.save(token)
  }

  func clearToken() -> Bool {
    return KeychainHelper.shared.delete()
  }

  func isTokenConfigured() -> Bool {
    return KeychainHelper.shared.exists()
  }

  private static let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter
  }()

  func fetchUser(username: String) async throws -> GitHubUser {
    // Check cache first
    if let cachedUser = dataManager.getCachedUser(for: username) {
      return cachedUser
    }

    guard let url = URL(string: "\(baseURL)/users/\(username)") else {
      throw URLError(.badURL)
    }

    let (data, _) = try await URLSession.shared.data(from: url)
    let user = try JSONDecoder().decode(GitHubUser.self, from: data)

    // Cache the user data
    dataManager.cacheUser(user, for: username)

    return user
  }

  func fetchContributions(username: String, days: Int = 365, useCache: Bool = true) async throws
    -> [ContributionDay]
  {
    // Check cache first if enabled
    if useCache {
      if let cachedContributions = dataManager.getCachedContributions(for: username) {
        return Array(cachedContributions.suffix(days))
      }
    }

    guard hasValidToken else {
      throw URLError(.userAuthenticationRequired)
    }

    let query = """
      query($userName: String!, $from: DateTime!, $to: DateTime!) {
          user(login: $userName) {
              contributionsCollection(from: $from, to: $to) {
                  contributionCalendar {
                      totalContributions
                      weeks {
                          contributionDays {
                              contributionCount
                              date
                          }
                      }
                  }
              }
          }
      }
      """

    // Calculate date range for exactly one year
    let calendar = Calendar.current
    let today = Date()
    let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today) ?? today

    let isoFormatter = ISO8601DateFormatter()
    let fromDate = isoFormatter.string(from: oneYearAgo)
    let toDate = isoFormatter.string(from: today)

    let variables: [String: Any] = [
      "userName": username,
      "from": fromDate,
      "to": toDate,
    ]
    let requestBody: [String: Any] = [
      "query": query,
      "variables": variables,
    ]

    guard let url = URL(string: graphQLURL) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(githubToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(GitHubGraphQLResponse.self, from: data)

    guard let user = response.data.user else {
      throw URLError(.userAuthenticationRequired)
    }

    // Flatten all contribution days from weeks
    var contributionMap: [String: Int] = [:]
    for week in user.contributionsCollection.contributionCalendar.weeks {
      for day in week.contributionDays {
        contributionMap[day.date] = day.contributionCount
      }
    }

    // Generate complete year of data, filling in missing days with 0 contributions
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    var allContributions: [ContributionDay] = []
    var currentDate = oneYearAgo

    while currentDate <= today {
      let dateString = dateFormatter.string(from: currentDate)
      let contributionCount = contributionMap[dateString] ?? 0

      allContributions.append(
        ContributionDay(
          date: dateString,
          contributionCount: contributionCount,
          color: ""
        ))

      currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
    }

    let contributions = Array(allContributions.suffix(days))

    // Cache the full year of data
    dataManager.cacheContributions(allContributions, for: username)

    return contributions
  }

  func getContributionIntensity(count: Int) -> Double {
    switch count {
    case 0: return 0.0
    case 1...3: return 0.25
    case 4...6: return 0.5
    case 7...9: return 0.75
    default: return 1.0
    }
  }

  func getContributionLevel(count: Int) -> Int {
    switch count {
    case 0: return 0
    case 1...3: return 1
    case 4...6: return 2
    case 7...9: return 3
    default: return 4
    }
  }
}
