//
//  Contribtuions_WidgetLiveActivity.swift
//  Contribtuions Widget
//
//  Created by Ahmed on 28.06.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Contribtuions_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Contribtuions_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Contribtuions_WidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Contribtuions_WidgetAttributes {
    fileprivate static var preview: Contribtuions_WidgetAttributes {
        Contribtuions_WidgetAttributes(name: "World")
    }
}

extension Contribtuions_WidgetAttributes.ContentState {
    fileprivate static var smiley: Contribtuions_WidgetAttributes.ContentState {
        Contribtuions_WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Contribtuions_WidgetAttributes.ContentState {
         Contribtuions_WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Contribtuions_WidgetAttributes.preview) {
   Contribtuions_WidgetLiveActivity()
} contentStates: {
    Contribtuions_WidgetAttributes.ContentState.smiley
    Contribtuions_WidgetAttributes.ContentState.starEyes
}
