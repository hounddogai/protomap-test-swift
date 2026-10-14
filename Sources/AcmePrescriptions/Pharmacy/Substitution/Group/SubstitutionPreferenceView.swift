import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution preference.
    final class SubstitutionPreferenceView {
        var code: String
        var name: String
        var amount: String
        var costText: String
        var expiresAtText: String
        var checksumText: String
        var weight: String
        var category: String
        var statusLabel: String

        init(code: String, name: String, amount: String, costText: String, expiresAtText: String, checksumText: String, weight: String, category: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.amount = amount
            self.costText = costText
            self.expiresAtText = expiresAtText
            self.checksumText = checksumText
            self.weight = weight
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionPreferenceView(_ item: SubstitutionPreference) -> SubstitutionPreferenceView {
        return SubstitutionPreferenceView(
            code: item.code,
            name: item.name,
            amount: String(format: "%.2f", item.amount),
            costText: String(format: "%.2f", item.cost),
            expiresAtText: String(item.expiresAt),
            checksumText: item.checksum,
            weight: String(format: "%.2f", item.weight),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionPreferenceViews(_ items: [SubstitutionPreference]) -> [SubstitutionPreferenceView] {
        var views: [SubstitutionPreferenceView] = []
        for item in items {
            views.append(toSubstitutionPreferenceView(item))
        }
        return views
    }

    static func sumSubstitutionPreferenceView(_ view: SubstitutionPreferenceView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedAmount + parsedCost + Double(parsedExpiresAt)
    }
}
