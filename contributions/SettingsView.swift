import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var userStore: UserStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedUser: UserSettings?
    @State private var showingColorPicker = false
    @State private var showingTokenSetup = false
    @State private var showingTokenAlert = false
    
    private let availableColors: [Color] = [
        .green, .blue, .purple, .orange, .red, .pink, .yellow, .teal
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section("GitHub Token") {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Access Token")
                                .font(.headline)
                            Text(GitHubService.shared.isTokenConfigured() ? "Configured" : "Not Set")
                                .font(.caption)
                                .foregroundColor(GitHubService.shared.isTokenConfigured() ? .green : .orange)
                        }
                        Spacer()
                        Button(GitHubService.shared.isTokenConfigured() ? "Update" : "Setup") {
                            showingTokenSetup = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if GitHubService.shared.isTokenConfigured() {
                        Button("Remove Token", role: .destructive) {
                            showingTokenAlert = true
                        }
                    }
                }
                
                Section("Users") {
                    if userStore.users.isEmpty {
                        Text("No users added")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(userStore.users, id: \.username) { user in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("@\(user.username)")
                                        .font(.headline)
                                    Text("Chart Color")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Circle()
                                    .fill(Color(hex: user.customColor))
                                    .frame(width: 30, height: 30)
                                    .onTapGesture {
                                        selectedUser = user
                                        showingColorPicker = true
                                    }
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Delete", role: .destructive) {
                                    userStore.removeUser(user.username)
                                }
                            }
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Version 1.0")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                if let user = selectedUser {
                    ColorPickerView(user: user, userStore: userStore)
                }
            }
            .sheet(isPresented: $showingTokenSetup) {
                GitHubTokenSetupView()
            }
            .alert("Remove GitHub Token", isPresented: $showingTokenAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    _ = GitHubService.shared.clearToken()
                }
            } message: {
                Text("This will remove your GitHub token from the secure Keychain. You'll need to set it up again to view contribution data.")
            }
        }
    }
}

struct ColorPickerView: View {
    let user: UserSettings
    @ObservedObject var userStore: UserStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedColor = Color.green
    
    private let availableColors: [Color] = [
        .green, .blue, .purple, .orange, .red, .pink, .yellow, .teal
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose a color for @\(user.username)")
                    .font(.headline)
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                    ForEach(availableColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 4)
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Color Picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        userStore.updateUserColor(user.username, color: selectedColor.toHex())
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedColor = Color(hex: user.customColor)
            }
        }
    }
}