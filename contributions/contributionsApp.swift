//
//  contributionsApp.swift
//  contributions
//
//  Created by Ahmed on 27.06.25.
//

import SwiftUI
import WidgetKit

@main
struct contributionsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }
}

struct ContributionWidgetBundle: WidgetBundle {
    var body: some Widget {
        ContributionWidget()
    }
}
