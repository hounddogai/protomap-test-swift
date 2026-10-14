import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot schedule.
    final class SlotScheduleView {
        var code: String
        var title: String
        var summary: String
        var graceDays: String
        var contactEmail: String
        var limit: String
        var visitMinutesText: String
        var windowDays: String
        var capacityText: String
        var cost: String
        var visibleText: String
        var statusLabel: String

        init(code: String, title: String, summary: String, graceDays: String, contactEmail: String, limit: String, visitMinutesText: String, windowDays: String, capacityText: String, cost: String, visibleText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.summary = summary
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.limit = limit
            self.visitMinutesText = visitMinutesText
            self.windowDays = windowDays
            self.capacityText = capacityText
            self.cost = cost
            self.visibleText = visibleText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotScheduleView(_ item: SlotSchedule) -> SlotScheduleView {
        return SlotScheduleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            summary: Kit.Text.truncate(item.summary, limit: 120),
            graceDays: String(item.graceDays),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            limit: String(item.limit),
            visitMinutesText: String(item.visitMinutes),
            windowDays: String(item.windowDays),
            capacityText: String(item.capacity),
            cost: String(format: "%.2f", item.cost),
            visibleText: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotScheduleViews(_ items: [SlotSchedule]) -> [SlotScheduleView] {
        var views: [SlotScheduleView] = []
        for item in items {
            views.append(toSlotScheduleView(item))
        }
        return views
    }

    static func sumSlotScheduleView(_ view: SlotScheduleView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedLimit) + Double(parsedVisitMinutes)
    }
}
