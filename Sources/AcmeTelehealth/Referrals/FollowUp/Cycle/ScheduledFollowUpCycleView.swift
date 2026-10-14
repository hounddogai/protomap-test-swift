import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a scheduled follow up cycle.
    final class ScheduledFollowUpCycleView {
        var codeText: String
        var titleText: String
        var windowDaysText: String
        var visitMinutesText: String
        var approved: String
        var statusLabel: String

        init(codeText: String, titleText: String, windowDaysText: String, visitMinutesText: String, approved: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.windowDaysText = windowDaysText
            self.visitMinutesText = visitMinutesText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledFollowUpCycleView(_ item: ScheduledFollowUpCycle) -> ScheduledFollowUpCycleView {
        return ScheduledFollowUpCycleView(
            codeText: item.code,
            titleText: item.title,
            windowDaysText: String(item.windowDays),
            visitMinutesText: String(item.visitMinutes),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledFollowUpCycleViews(_ items: [ScheduledFollowUpCycle]) -> [ScheduledFollowUpCycleView] {
        var views: [ScheduledFollowUpCycleView] = []
        for item in items {
            views.append(toScheduledFollowUpCycleView(item))
        }
        return views
    }

    static func sumScheduledFollowUpCycleView(_ view: ScheduledFollowUpCycleView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedVisitMinutes)
    }
}
