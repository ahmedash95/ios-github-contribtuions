import Foundation
import Combine

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


struct ContributionDay: Codable, Identifiable {
    let id = UUID()
    let date: String
    let contributionCount: Int
    let color: String
    
    enum CodingKeys: String, CodingKey {
        case date, contributionCount, color
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
    let customColor: String
    let id: UUID
    
    init(username: String, customColor: String) {
        self.username = username
        self.customColor = customColor
        self.id = UUID()
    }
}

class UserStore: ObservableObject {
    @Published var users: [UserSettings] = []
    
    private let userDefaultsKey = "SavedUsers"
    
    init() {
        loadUsers()
    }
    
    func addUser(_ username: String, color: String = "#28a745") {
        let newUser = UserSettings(username: username, customColor: color)
        users.append(newUser)
        saveUsers()
    }
    
    func removeUser(_ username: String) {
        users.removeAll { $0.username == username }
        saveUsers()
    }
    
    func updateUserColor(_ username: String, color: String) {
        if let index = users.firstIndex(where: { $0.username == username }) {
            users[index] = UserSettings(username: username, customColor: color)
            saveUsers()
        }
    }
    
    private func saveUsers() {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadUsers() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedUsers = try? JSONDecoder().decode([UserSettings].self, from: data) {
            users = savedUsers
        }
    }
}