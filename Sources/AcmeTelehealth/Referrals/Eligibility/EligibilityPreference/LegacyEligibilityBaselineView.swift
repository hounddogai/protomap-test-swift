import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a legacy eligibility baseline.
    final class LegacyEligibilityBaselineView {
        var codeText: String
        var name: String
        var payerText: String
        var currency: String
        var ratio: String
        var archivedText: String
        var patientRefText: String
        var maximum: String
        var ceiling: String
        var startsAt: String
        var statusLabel: String

        init(codeText: String, name: String, payerText: String, currency: String, ratio: String, archivedText: String, patientRefText: String, maximum: String, ceiling: String, startsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.payerText = payerText
            self.currency = currency
            self.ratio = ratio
            self.archivedText = archivedText
            self.patientRefText = patientRefText
            self.maximum = maximum
            self.ceiling = ceiling
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyEligibilityBaselineView(_ item: LegacyEligibilityBaseline) -> LegacyEligibilityBaselineView {
        return LegacyEligibilityBaselineView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 80),
            payerText: item.payer,
            currency: item.currency,
            ratio: String(format: "%.2f", item.ratio),
            archivedText: "\(item.archived)",
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            ceiling: String(format: "%.2f", item.ceiling),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyEligibilityBaselineViews(_ items: [LegacyEligibilityBaseline]) -> [LegacyEligibilityBaselineView] {
        var views: [LegacyEligibilityBaselineView] = []
        for item in items {
            views.append(toLegacyEligibilityBaselineView(item))
        }
        return views
    }

    static func sumLegacyEligibilityBaselineView(_ view: LegacyEligibilityBaselineView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedRatio + parsedMaximum + parsedCeiling
    }
}
