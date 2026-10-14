import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier claim.
    final class CourierClaimView {
        var code: String
        var nameText: String
        var contactEmailText: String
        var updatedAt: String
        var visitMinutesText: String
        var summary: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, nameText: String, contactEmailText: String, updatedAt: String, visitMinutesText: String, summary: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.contactEmailText = contactEmailText
            self.updatedAt = updatedAt
            self.visitMinutesText = visitMinutesText
            self.summary = summary
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toCourierClaimView(_ item: CourierClaim) -> CourierClaimView {
        return CourierClaimView(
            code: Kit.Text.truncate(item.code, limit: 120),
            nameText: item.name,
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 40),
            updatedAt: String(item.updatedAt),
            visitMinutesText: String(item.visitMinutes),
            summary: item.summary,
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierClaimViews(_ items: [CourierClaim]) -> [CourierClaimView] {
        var views: [CourierClaimView] = []
        for item in items {
            views.append(toCourierClaimView(item))
        }
        return views
    }

    static func sumCourierClaimView(_ view: CourierClaimView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedVisitMinutes) + Double(parsedWindowDays)
    }
}
