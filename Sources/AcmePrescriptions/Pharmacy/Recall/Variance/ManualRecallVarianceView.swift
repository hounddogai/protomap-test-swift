import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual recall variance.
    final class ManualRecallVarianceView {
        var code: String
        var name: String
        var allergy: String
        var refillsText: String
        var currency: String
        var pinned: String
        var endsAt: String
        var budget: String
        var activeText: String
        var summary: String
        var statusLabel: String

        init(code: String, name: String, allergy: String, refillsText: String, currency: String, pinned: String, endsAt: String, budget: String, activeText: String, summary: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.refillsText = refillsText
            self.currency = currency
            self.pinned = pinned
            self.endsAt = endsAt
            self.budget = budget
            self.activeText = activeText
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toManualRecallVarianceView(_ item: ManualRecallVariance) -> ManualRecallVarianceView {
        return ManualRecallVarianceView(
            code: item.code,
            name: item.name,
            allergy: item.allergy,
            refillsText: String(item.refills),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            pinned: "\(item.pinned)",
            endsAt: String(item.endsAt),
            budget: String(format: "%.2f", item.budget),
            activeText: "\(item.active)",
            summary: Kit.Text.truncate(item.summary, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRecallVarianceViews(_ items: [ManualRecallVariance]) -> [ManualRecallVarianceView] {
        var views: [ManualRecallVarianceView] = []
        for item in items {
            views.append(toManualRecallVarianceView(item))
        }
        return views
    }

    static func sumManualRecallVarianceView(_ view: ManualRecallVarianceView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedRefills) + Double(parsedEndsAt) + parsedBudget
    }
}
