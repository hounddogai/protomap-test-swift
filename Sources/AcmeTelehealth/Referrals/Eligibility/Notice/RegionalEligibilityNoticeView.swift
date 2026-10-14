import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional eligibility notice.
    final class RegionalEligibilityNoticeView {
        var code: String
        var title: String
        var maximum: String
        var expiresAt: String
        var visitMinutes: String
        var visibleText: String
        var archived: String
        var weight: String
        var version: String
        var unit: String
        var statusLabel: String

        init(code: String, title: String, maximum: String, expiresAt: String, visitMinutes: String, visibleText: String, archived: String, weight: String, version: String, unit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.expiresAt = expiresAt
            self.visitMinutes = visitMinutes
            self.visibleText = visibleText
            self.archived = archived
            self.weight = weight
            self.version = version
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalEligibilityNoticeView(_ item: RegionalEligibilityNotice) -> RegionalEligibilityNoticeView {
        return RegionalEligibilityNoticeView(
            code: item.code,
            title: item.title,
            maximum: String(format: "%.2f", item.maximum),
            expiresAt: String(item.expiresAt),
            visitMinutes: String(item.visitMinutes),
            visibleText: "\(item.visible)",
            archived: "\(item.archived)",
            weight: String(format: "%.2f", item.weight),
            version: String(item.version),
            unit: Kit.Text.truncate(item.unit, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalEligibilityNoticeViews(_ items: [RegionalEligibilityNotice]) -> [RegionalEligibilityNoticeView] {
        var views: [RegionalEligibilityNoticeView] = []
        for item in items {
            views.append(toRegionalEligibilityNoticeView(item))
        }
        return views
    }

    static func sumRegionalEligibilityNoticeView(_ view: RegionalEligibilityNoticeView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedMaximum + Double(parsedExpiresAt) + Double(parsedVisitMinutes)
    }
}
