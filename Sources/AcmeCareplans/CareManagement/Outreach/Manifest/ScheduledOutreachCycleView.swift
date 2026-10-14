import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled outreach cycle.
    final class ScheduledOutreachCycleView {
        var codeText: String
        var label: String
        var ceilingText: String
        var channelText: String
        var statusLabel: String

        init(codeText: String, label: String, ceilingText: String, channelText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ceilingText = ceilingText
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledOutreachCycleView(_ item: ScheduledOutreachCycle) -> ScheduledOutreachCycleView {
        return ScheduledOutreachCycleView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            ceilingText: String(format: "%.2f", item.ceiling),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledOutreachCycleViews(_ items: [ScheduledOutreachCycle]) -> [ScheduledOutreachCycleView] {
        var views: [ScheduledOutreachCycleView] = []
        for item in items {
            views.append(toScheduledOutreachCycleView(item))
        }
        return views
    }

    static func sumScheduledOutreachCycleView(_ view: ScheduledOutreachCycleView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
