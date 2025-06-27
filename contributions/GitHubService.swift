import Foundation
import Combine

class GitHubService: ObservableObject {
    static let shared = GitHubService()
    
    private let baseURL = "https://api.github.com"
    private let graphQLURL = "https://api.github.com/graphql"
    
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
        guard let url = URL(string: "\(baseURL)/users/\(username)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(GitHubUser.self, from: data)
    }
    
    func fetchContributions(username: String, days: Int = 112) async throws -> [ContributionDay] {
        guard hasValidToken else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let query = """
        query($userName: String!) {
            user(login: $userName) {
                contributionsCollection {
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
        
        let variables = ["userName": username]
        let requestBody: [String: Any] = [
            "query": query,
            "variables": variables
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
        var allContributions: [ContributionDay] = []
        for week in user.contributionsCollection.contributionCalendar.weeks {
            for day in week.contributionDays {
                allContributions.append(ContributionDay(
                    date: day.date,
                    contributionCount: day.contributionCount,
                    color: ""
                ))
            }
        }
        
        // Return the most recent days
        return Array(allContributions.suffix(days))
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