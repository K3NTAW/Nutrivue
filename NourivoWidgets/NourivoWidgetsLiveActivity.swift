//
//  NourivoWidgetsLiveActivity.swift
//  NourivoWidgets
//
//  Created by Kenta Waibel on 18.09.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct NourivoWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct NourivoWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NourivoWidgetsAttributes.self) { context in
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

extension NourivoWidgetsAttributes {
    fileprivate static var preview: NourivoWidgetsAttributes {
        NourivoWidgetsAttributes(name: "World")
    }
}

extension NourivoWidgetsAttributes.ContentState {
    fileprivate static var smiley: NourivoWidgetsAttributes.ContentState {
        NourivoWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: NourivoWidgetsAttributes.ContentState {
         NourivoWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: NourivoWidgetsAttributes.preview) {
   NourivoWidgetsLiveActivity()
} contentStates: {
    NourivoWidgetsAttributes.ContentState.smiley
    NourivoWidgetsAttributes.ContentState.starEyes
}
