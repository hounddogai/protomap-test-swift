import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language preference.
    final class LanguagePreferenceView {
        var code: String
        var title: String
        var ceiling: String
        var label: String
        var discountText: String
        var rate: String
        var minimum: String
        var descriptionText: String
        var statusLabel: String

        init(code: String, title: String, ceiling: String, label: String, discountText: String, rate: String, minimum: String, descriptionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.label = label
            self.discountText = discountText
            self.rate = rate
            self.minimum = minimum
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toLanguagePreferenceView(_ item: LanguagePreference) -> LanguagePreferenceView {
        return LanguagePreferenceView(
            code: item.code,
            title: item.title,
            ceiling: String(format: "%.2f", item.ceiling),
            label: item.label,
            discountText: String(format: "%.2f", item.discount),
            rate: String(format: "%.2f", item.rate),
            minimum: String(format: "%.2f", item.minimum),
            descriptionText: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguagePreferenceViews(_ items: [LanguagePreference]) -> [LanguagePreferenceView] {
        var views: [LanguagePreferenceView] = []
        for item in items {
            views.append(toLanguagePreferenceView(item))
        }
        return views
    }

    static func sumLanguagePreferenceView(_ view: LanguagePreferenceView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedCeiling + parsedDiscount + parsedRate
    }
}
