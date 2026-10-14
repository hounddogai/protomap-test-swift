import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language template.
    final class LanguageTemplateView {
        var code: String
        var title: String
        var quantity: String
        var allergy: String
        var category: String
        var statusLabel: String

        init(code: String, title: String, quantity: String, allergy: String, category: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.allergy = allergy
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageTemplateView(_ item: LanguageTemplate) -> LanguageTemplateView {
        return LanguageTemplateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            quantity: String(item.quantity),
            allergy: item.allergy,
            category: Kit.Text.truncate(item.category, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageTemplateViews(_ items: [LanguageTemplate]) -> [LanguageTemplateView] {
        var views: [LanguageTemplateView] = []
        for item in items {
            views.append(toLanguageTemplateView(item))
        }
        return views
    }

    static func sumLanguageTemplateView(_ view: LanguageTemplateView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
