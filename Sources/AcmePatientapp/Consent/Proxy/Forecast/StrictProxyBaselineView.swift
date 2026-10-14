import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict proxy baseline.
    final class StrictProxyBaselineView {
        var codeText: String
        var title: String
        var contactEmail: String
        var graceDaysText: String
        var refills: String
        var archived: String
        var allergyText: String
        var amount: String
        var statusLabel: String

        init(codeText: String, title: String, contactEmail: String, graceDaysText: String, refills: String, archived: String, allergyText: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.contactEmail = contactEmail
            self.graceDaysText = graceDaysText
            self.refills = refills
            self.archived = archived
            self.allergyText = allergyText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toStrictProxyBaselineView(_ item: StrictProxyBaseline) -> StrictProxyBaselineView {
        return StrictProxyBaselineView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            graceDaysText: String(item.graceDays),
            refills: String(item.refills),
            archived: "\(item.archived)",
            allergyText: item.allergy,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictProxyBaselineViews(_ items: [StrictProxyBaseline]) -> [StrictProxyBaselineView] {
        var views: [StrictProxyBaselineView] = []
        for item in items {
            views.append(toStrictProxyBaselineView(item))
        }
        return views
    }

    static func sumStrictProxyBaselineView(_ view: StrictProxyBaselineView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedRefills) + parsedAmount
    }
}
