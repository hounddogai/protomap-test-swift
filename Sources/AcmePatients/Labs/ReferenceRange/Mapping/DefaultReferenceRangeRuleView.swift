import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a default reference range rule.
    final class DefaultReferenceRangeRuleView {
        var codeText: String
        var title: String
        var countryText: String
        var score: String
        var payer: String
        var quantity: String
        var contactEmail: String
        var statusLabel: String

        init(codeText: String, title: String, countryText: String, score: String, payer: String, quantity: String, contactEmail: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.countryText = countryText
            self.score = score
            self.payer = payer
            self.quantity = quantity
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultReferenceRangeRuleView(_ item: DefaultReferenceRangeRule) -> DefaultReferenceRangeRuleView {
        return DefaultReferenceRangeRuleView(
            codeText: item.code,
            title: item.title,
            countryText: Kit.Text.truncate(item.country, limit: 120),
            score: String(format: "%.2f", item.score),
            payer: item.payer,
            quantity: String(item.quantity),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultReferenceRangeRuleViews(_ items: [DefaultReferenceRangeRule]) -> [DefaultReferenceRangeRuleView] {
        var views: [DefaultReferenceRangeRuleView] = []
        for item in items {
            views.append(toDefaultReferenceRangeRuleView(item))
        }
        return views
    }

    static func sumDefaultReferenceRangeRuleView(_ view: DefaultReferenceRangeRuleView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedScore + Double(parsedQuantity)
    }
}
