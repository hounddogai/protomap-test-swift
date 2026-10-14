import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a tiered disclosure digest.
    final class TieredDisclosureDigestView {
        var code: String
        var title: String
        var rateText: String
        var expiresAt: String
        var sourceText: String
        var budget: String
        var amount: String
        var statusLabel: String

        init(code: String, title: String, rateText: String, expiresAt: String, sourceText: String, budget: String, amount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.rateText = rateText
            self.expiresAt = expiresAt
            self.sourceText = sourceText
            self.budget = budget
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toTieredDisclosureDigestView(_ item: TieredDisclosureDigest) -> TieredDisclosureDigestView {
        return TieredDisclosureDigestView(
            code: item.code,
            title: item.title,
            rateText: String(format: "%.2f", item.rate),
            expiresAt: String(item.expiresAt),
            sourceText: item.source,
            budget: String(format: "%.2f", item.budget),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredDisclosureDigestViews(_ items: [TieredDisclosureDigest]) -> [TieredDisclosureDigestView] {
        var views: [TieredDisclosureDigestView] = []
        for item in items {
            views.append(toTieredDisclosureDigestView(item))
        }
        return views
    }

    static func sumTieredDisclosureDigestView(_ view: TieredDisclosureDigestView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedRate + Double(parsedExpiresAt) + parsedBudget
    }
}
