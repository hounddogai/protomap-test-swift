import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential preference.
    final class CredentialPreferenceView {
        var code: String
        var nameText: String
        var costText: String
        var segment: String
        var amount: String
        var statusLabel: String

        init(code: String, nameText: String, costText: String, segment: String, amount: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.costText = costText
            self.segment = segment
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialPreferenceView(_ item: CredentialPreference) -> CredentialPreferenceView {
        return CredentialPreferenceView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            costText: String(format: "%.2f", item.cost),
            segment: item.segment,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialPreferenceViews(_ items: [CredentialPreference]) -> [CredentialPreferenceView] {
        var views: [CredentialPreferenceView] = []
        for item in items {
            views.append(toCredentialPreferenceView(item))
        }
        return views
    }

    static func sumCredentialPreferenceView(_ view: CredentialPreferenceView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedCost + parsedAmount
    }
}
