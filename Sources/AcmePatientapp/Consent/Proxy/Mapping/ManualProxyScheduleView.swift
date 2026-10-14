import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual proxy schedule.
    final class ManualProxyScheduleView {
        var code: String
        var title: String
        var name: String
        var windowDays: String
        var priorityText: String
        var endsAtText: String
        var summaryText: String
        var quantity: String
        var statusLabel: String

        init(code: String, title: String, name: String, windowDays: String, priorityText: String, endsAtText: String, summaryText: String, quantity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.name = name
            self.windowDays = windowDays
            self.priorityText = priorityText
            self.endsAtText = endsAtText
            self.summaryText = summaryText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toManualProxyScheduleView(_ item: ManualProxySchedule) -> ManualProxyScheduleView {
        return ManualProxyScheduleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 80),
            windowDays: String(item.windowDays),
            priorityText: String(item.priority),
            endsAtText: String(item.endsAt),
            summaryText: Kit.Text.truncate(item.summary, limit: 40),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualProxyScheduleViews(_ items: [ManualProxySchedule]) -> [ManualProxyScheduleView] {
        var views: [ManualProxyScheduleView] = []
        for item in items {
            views.append(toManualProxyScheduleView(item))
        }
        return views
    }

    static func sumManualProxyScheduleView(_ view: ManualProxyScheduleView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedPriority) + Double(parsedEndsAt)
    }
}
