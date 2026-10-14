import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped eligibility rollup.
    final class CappedEligibilityRollupView {
        var code: String
        var label: String
        var refillsText: String
        var name: String
        var activeText: String
        var localeText: String
        var attempts: String
        var approved: String
        var discountText: String
        var statusLabel: String

        init(code: String, label: String, refillsText: String, name: String, activeText: String, localeText: String, attempts: String, approved: String, discountText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.refillsText = refillsText
            self.name = name
            self.activeText = activeText
            self.localeText = localeText
            self.attempts = attempts
            self.approved = approved
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedEligibilityRollupView(_ item: CappedEligibilityRollup) -> CappedEligibilityRollupView {
        return CappedEligibilityRollupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            refillsText: String(item.refills),
            name: item.name,
            activeText: "\(item.active)",
            localeText: item.locale,
            attempts: String(item.attempts),
            approved: "\(item.approved)",
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedEligibilityRollupViews(_ items: [CappedEligibilityRollup]) -> [CappedEligibilityRollupView] {
        var views: [CappedEligibilityRollupView] = []
        for item in items {
            views.append(toCappedEligibilityRollupView(item))
        }
        return views
    }

    static func sumCappedEligibilityRollupView(_ view: CappedEligibilityRollupView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedRefills) + Double(parsedAttempts) + parsedDiscount
    }
}
