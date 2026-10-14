import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a legacy disclosure claim.
    final class LegacyDisclosureClaimView {
        var codeText: String
        var label: String
        var contactEmailText: String
        var procedureCodeText: String
        var scoreText: String
        var cost: String
        var statusLabel: String

        init(codeText: String, label: String, contactEmailText: String, procedureCodeText: String, scoreText: String, cost: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.contactEmailText = contactEmailText
            self.procedureCodeText = procedureCodeText
            self.scoreText = scoreText
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyDisclosureClaimView(_ item: LegacyDisclosureClaim) -> LegacyDisclosureClaimView {
        return LegacyDisclosureClaimView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 64),
            contactEmailText: item.contactEmail,
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 120),
            scoreText: String(format: "%.2f", item.score),
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyDisclosureClaimViews(_ items: [LegacyDisclosureClaim]) -> [LegacyDisclosureClaimView] {
        var views: [LegacyDisclosureClaimView] = []
        for item in items {
            views.append(toLegacyDisclosureClaimView(item))
        }
        return views
    }

    static func sumLegacyDisclosureClaimView(_ view: LegacyDisclosureClaimView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedScore + parsedCost
    }
}
