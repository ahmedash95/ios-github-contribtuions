import Foundation

struct ErrorHandler {
  static func getErrorMessage(for error: Error) -> String {
    if let githubError = error as? GitHubError {
      return githubError.errorDescription ?? "GitHub API error occurred"
    } else if let urlError = error as? URLError {
      return getURLErrorMessage(urlError)
    } else {
      return "An unexpected error occurred"
    }
  }

  private static func getURLErrorMessage(_ error: URLError) -> String {
    switch error.code {
    case .notConnectedToInternet:
      return "No internet connection"
    case .timedOut:
      return "Request timed out"
    case .cannotFindHost:
      return "Cannot connect to GitHub"
    case .userAuthenticationRequired:
      return "Authentication required"
    case .badURL:
      return "Invalid URL"
    case .badServerResponse:
      return "Server error"
    default:
      return "Network error occurred"
    }
  }

  static func getUsernameValidationError(for username: String, existingUsers: [UserSettings])
    -> String?
  {
    // Basic validation
    if username.isEmpty {
      return "Please enter a username"
    }

    // Username format validation
    let usernameRegex = "^[a-zA-Z0-9](?:[a-zA-Z0-9]|-(?=[a-zA-Z0-9])){0,38}$"
    if username.range(of: usernameRegex, options: .regularExpression) == nil {
      return "Invalid GitHub username format"
    }

    // Duplicate check
    if existingUsers.contains(where: { $0.username.lowercased() == username.lowercased() }) {
      return "User already exists"
    }

    return nil
  }
}
