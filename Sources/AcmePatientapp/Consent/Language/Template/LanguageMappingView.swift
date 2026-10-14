import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language mapping.
    final class LanguageMappingView {
        var codeText: String
        var label: String
        var discount: String
        var createdAt: String
        var startsAtText: String
        var ceiling: String
        var timezone: String
        var quantity: String
        var summary: String
        var payer: String
        var statusLabel: String

        init(codeText: String, label: String, discount: String, createdAt: String, startsAtText: String, ceiling: String, timezone: String, quantity: String, summary: String, payer: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.discount = discount
            self.createdAt = createdAt
            self.startsAtText = startsAtText
            self.ceiling = ceiling
            self.timezone = timezone
            self.quantity = quantity
            self.summary = summary
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageMappingView(_ item: LanguageMapping) -> LanguageMappingView {
        return LanguageMappingView(
            codeText: item.code,
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            createdAt: String(item.createdAt),
            startsAtText: String(item.startsAt),
            ceiling: String(format: "%.2f", item.ceiling),
            timezone: item.timezone,
            quantity: String(item.quantity),
            summary: item.summary,
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageMappingViews(_ items: [LanguageMapping]) -> [LanguageMappingView] {
        var views: [LanguageMappingView] = []
        for item in items {
            views.append(toLanguageMappingView(item))
        }
        return views
    }

    static func sumLanguageMappingView(_ view: LanguageMappingView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedDiscount + Double(parsedCreatedAt) + Double(parsedStartsAt)
    }
}
