import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen target.
    final class SpecimenTargetView {
        var code: String
        var label: String
        var currency: String
        var phone: String
        var budgetText: String
        var statusLabel: String

        init(code: String, label: String, currency: String, phone: String, budgetText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.currency = currency
            self.phone = phone
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenTargetView(_ item: SpecimenTarget) -> SpecimenTargetView {
        return SpecimenTargetView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            phone: item.phone,
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenTargetViews(_ items: [SpecimenTarget]) -> [SpecimenTargetView] {
        var views: [SpecimenTargetView] = []
        for item in items {
            views.append(toSpecimenTargetView(item))
        }
        return views
    }

    static func sumSpecimenTargetView(_ view: SpecimenTargetView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedBudget
    }
}
