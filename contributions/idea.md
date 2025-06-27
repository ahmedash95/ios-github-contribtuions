# GitHub Contributions iOS App

## Overview

The GitHub Contributions iOS App is a sleek, intuitive application designed to display GitHub users' contribution graphs. Built with SwiftUI, the app makes use of the GitHub API to fetch and display contribution data. Users can add GitHub usernames, view contribution charts, and customize the appearance. The app will also support iOS widgets in small, medium, and large sizes.

## Core Features

### User Management
- **Add User:** A form to input and save GitHub usernames.
- **Display User Information:** Each contributions chart will show the username and avatar of the GitHub user.

### Contribution Charts
- **Contribution Display:** Use a package to render contribution charts as a grid of colored dots. Each dot represents a day; its color intensity corresponds to the number of commits.
- **Customization:** Enable users to choose a custom color for each contributions chart instead of the default green.

### iOS Widgets
- **Widgets Types:** Support for small, medium, and large widgets.
- **Display Options:**
  - Single User: If one user is selected, display a single contributions chart.
  - Multiple Users: If multiple users are selected (up to 4), display each user's contributions on a single line in the widget.
- **Time Frame:** Display contributions for the last X days (e.g., 7 days).

## UI/UX Design

### Main App Interface
1. **Home Screen:**
   - Add User Button.
   - List of Users with Avatars and Usernames.
   - Contribution Chart with customization options.

2. **Add User Form:**
   - Input field to enter GitHub username.
   - Submit button to add the user.

3. **Settings:**
   - Options to choose custom colors for contributions charts.
   - Manage list of users.

### Widget Interface
1. **Small Widget:**
   - Display contributions chart for 1 user.

2. **Medium Widget:**
   - Display contributions chart for up to 2 users.

3. **Large Widget:**
   - Display contributions chart for up to 4 users.

## Technical Requirements

- **Language:** Swift
- **Framework:** SwiftUI
- **API:** GitHub REST API v3 for fetching user contributions.
- **Third-Party Libraries:** Consider using a library for rendering contribution grids (e.g., Swift package that supports grid view).

## Development Phases

1. **Prototype & Design:**
   - Sketch UI and widget layout.
   - Choose color scheme and design elements.

2. **Backend Implementation:**
   - Integrate with GitHub API to fetch user data.
   - Handle authentication if required by GitHub API.

3. **Frontend Development:**
   - Implement UI with SwiftUI.
   - Integrate third-party library for contribution chart rendering.

4. **Widget Development:**
   - Implement small, medium, and large widget configurations.
