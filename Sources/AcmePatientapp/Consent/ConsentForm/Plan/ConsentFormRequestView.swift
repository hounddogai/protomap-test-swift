import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form request.
    final class ConsentFormRequestView {
        var code: String
        var labelText: String
        var budget: String
        var expiresAt: String
        var ward: String
        var description: String
        var statusLabel: String

        init(code: String, labelText: String, budget: String, expiresAt: String, ward: String, description: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.budget = budget
            self.expiresAt = expiresAt
            self.ward = ward
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormRequestView(_ item: ConsentFormRequest) -> ConsentFormRequestView {
        return ConsentFormRequestView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            budget: String(format: "%.2f", item.budget),
            expiresAt: String(item.expiresAt),
            ward: item.ward,
            description: Kit.Text.truncate(item.description, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormRequestViews(_ items: [ConsentFormRequest]) -> [ConsentFormRequestView] {
        var views: [ConsentFormRequestView] = []
        for item in items {
            views.append(toConsentFormRequestView(item))
        }
        return views
    }

    static func sumConsentFormRequestView(_ view: ConsentFormRequestView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedBudget + Double(parsedExpiresAt)
    }
}
