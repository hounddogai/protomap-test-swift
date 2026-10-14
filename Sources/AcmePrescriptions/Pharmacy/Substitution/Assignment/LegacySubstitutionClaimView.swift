import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy substitution claim.
    final class LegacySubstitutionClaimView {
        var code: String
        var title: String
        var attempts: String
        var weight: String
        var graceDays: String
        var score: String
        var label: String
        var quantity: String
        var archived: String
        var statusLabel: String

        init(code: String, title: String, attempts: String, weight: String, graceDays: String, score: String, label: String, quantity: String, archived: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.weight = weight
            self.graceDays = graceDays
            self.score = score
            self.label = label
            self.quantity = quantity
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toLegacySubstitutionClaimView(_ item: LegacySubstitutionClaim) -> LegacySubstitutionClaimView {
        return LegacySubstitutionClaimView(
            code: item.code,
            title: item.title,
            attempts: String(item.attempts),
            weight: String(format: "%.2f", item.weight),
            graceDays: String(item.graceDays),
            score: String(format: "%.2f", item.score),
            label: Kit.Text.truncate(item.label, limit: 40),
            quantity: String(item.quantity),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacySubstitutionClaimViews(_ items: [LegacySubstitutionClaim]) -> [LegacySubstitutionClaimView] {
        var views: [LegacySubstitutionClaimView] = []
        for item in items {
            views.append(toLegacySubstitutionClaimView(item))
        }
        return views
    }

    static func sumLegacySubstitutionClaimView(_ view: LegacySubstitutionClaimView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedAttempts) + parsedWeight + Double(parsedGraceDays)
    }
}
