import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility override.
    final class EligibilityOverrideView {
        var code: String
        var title: String
        var ownerID: String
        var facility: String
        var ward: String
        var notes: String
        var summaryText: String
        var amount: String
        var statusLabel: String

        init(code: String, title: String, ownerID: String, facility: String, ward: String, notes: String, summaryText: String, amount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.facility = facility
            self.ward = ward
            self.notes = notes
            self.summaryText = summaryText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityOverrideView(_ item: EligibilityOverride) -> EligibilityOverrideView {
        return EligibilityOverrideView(
            code: item.code,
            title: item.title,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            facility: Kit.Text.truncate(item.facility, limit: 64),
            ward: item.ward,
            notes: item.notes,
            summaryText: Kit.Text.truncate(item.summary, limit: 80),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityOverrideViews(_ items: [EligibilityOverride]) -> [EligibilityOverrideView] {
        var views: [EligibilityOverrideView] = []
        for item in items {
            views.append(toEligibilityOverrideView(item))
        }
        return views
    }

    static func sumEligibilityOverrideView(_ view: EligibilityOverrideView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
