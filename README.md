# GitHub Contributions iOS App & Widget

<p align="center">
  <img src="resources/icon.png" width="128" height="128" alt="App Icon">
</p>

> [!NOTE]
> Welcome! This project was vibe coded with Cursor by an amateur Swift developer learning the ropes. While the code may not be perfect and could benefit from some refactoring, it's built with care and enthusiasm. Your feedback, suggestions, and contributions to help improve this project would mean the world to me. Thank you for taking the time to explore this little corner of my coding journey! 🚀

## Screenshots

| <img src="resources/screenshots/Apple iPhone 16 Pro Max (1320x2868)/Apple iPhone 16 Pro Max Screenshot 1.png" width="200" height="400" alt="Screenshot 1"> | <img src="resources/screenshots/Apple iPhone 16 Pro Max (1320x2868)/Apple iPhone 16 Pro Max Screenshot 2.png" width="200" height="400" alt="Screenshot 2"> | <img src="resources/screenshots/Apple iPhone 16 Pro Max (1320x2868)/Apple iPhone 16 Pro Max Screenshot 3.png" width="200" height="400" alt="Screenshot 3"> | <img src="resources/screenshots/Apple iPhone 16 Pro Max (1320x2868)/Apple iPhone 16 Pro Max Screenshot 4.png" width="200" height="400" alt="Screenshot 4"> | <img src="resources/screenshots/Apple iPhone 16 Pro Max (1320x2868)/Apple iPhone 16 Pro Max Screenshot 5.png" width="200" height="400" alt="Screenshot 5"> |
| :--------------------------------------------------------------------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------: | :--------------------------------------------------------------------------------------------------------------------------------------------------------: |

## Overview

A sleek iOS app that displays GitHub contribution graphs with customizable widgets. Built with SwiftUI and the GitHub API.

## Features

- **Contribution Charts**: View GitHub contribution graphs for any user
- **iOS Widgets**: Small and medium widgets for quick contribution viewing
- **User Management**: Add multiple GitHub users with custom color themes
- **Offline Support**: Cached data ensures widgets work without internet
- **Secure**: GitHub token stored securely in Keychain

## Setup

1. Add GitHub usernames in the app
2. Configure GitHub token for API access
3. Add widgets to your home screen
4. Select users to display in widgets

## Widget Configuration

- Long press widget → Edit Widget → Select user
- Widgets refresh automatically every hour
- Works offline using cached data

## Requirements

- iOS 17.0+
- GitHub account with personal access token
- App Groups capability configured for widget data sharing
