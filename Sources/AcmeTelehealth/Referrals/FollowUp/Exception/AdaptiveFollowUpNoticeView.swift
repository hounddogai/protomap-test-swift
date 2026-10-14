import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a adaptive follow up notice.
    final class AdaptiveFollowUpNoticeView {
        var code: String
        var labelText: String
        var windowDaysText: String
        var priority: String
        var timezone: String
        var minimum: String
        var statusLabel: String

        init(code: String, labelText: String, windowDaysText: String, priority: String, timezone: String, minimum: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.windowDaysText = windowDaysText
            self.priority = priority
            self.timezone = timezone
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveFollowUpNoticeView(_ item: AdaptiveFollowUpNotice) -> AdaptiveFollowUpNoticeView {
        return AdaptiveFollowUpNoticeView(
            code: item.code,
            labelText: item.label,
            windowDaysText: String(item.windowDays),
            priority: String(item.priority),
            timezone: item.timezone,
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveFollowUpNoticeViews(_ items: [AdaptiveFollowUpNotice]) -> [AdaptiveFollowUpNoticeView] {
        var views: [AdaptiveFollowUpNoticeView] = []
        for item in items {
            views.append(toAdaptiveFollowUpNoticeView(item))
        }
        return views
    }

    static func sumAdaptiveFollowUpNoticeView(_ view: AdaptiveFollowUpNoticeView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedPriority) + parsedMinimum
    }
}
