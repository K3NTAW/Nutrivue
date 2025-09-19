//
//  NutrivueWidgetsLiveActivity.swift
//  NutrivueWidgets
//
//  Created by Kenta Waibel on 18.09.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct NutrivueWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct NutrivueWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NutrivueWidgetsAttributes.self) { context in
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

extension NutrivueWidgetsAttributes {
    fileprivate static var preview: NutrivueWidgetsAttributes {
        NutrivueWidgetsAttributes(name: "World")
    }
}

extension NutrivueWidgetsAttributes.ContentState {
    fileprivate static var smiley: NutrivueWidgetsAttributes.ContentState {
        NutrivueWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: NutrivueWidgetsAttributes.ContentState {
         NutrivueWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: NutrivueWidgetsAttributes.preview) {
   NutrivueWidgetsLiveActivity()
} contentStates: {
    NutrivueWidgetsAttributes.ContentState.smiley
    NutrivueWidgetsAttributes.ContentState.starEyes
}
