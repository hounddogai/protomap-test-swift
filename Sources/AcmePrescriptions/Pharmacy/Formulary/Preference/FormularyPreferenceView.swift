import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary preference.
    final class FormularyPreferenceView {
        var code: String
        var nameText: String
        var externalRef: String
        var unitText: String
        var budgetText: String
        var notes: String
        var locale: String
        var categoryText: String
        var statusLabel: String

        init(code: String, nameText: String, externalRef: String, unitText: String, budgetText: String, notes: String, locale: String, categoryText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.externalRef = externalRef
            self.unitText = unitText
            self.budgetText = budgetText
            self.notes = notes
            self.locale = locale
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyPreferenceView(_ item: FormularyPreference) -> FormularyPreferenceView {
        return FormularyPreferenceView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            externalRef: item.externalRef,
            unitText: Kit.Text.truncate(item.unit, limit: 80),
            budgetText: String(format: "%.2f", item.budget),
            notes: item.notes,
            locale: item.locale,
            categoryText: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyPreferenceViews(_ items: [FormularyPreference]) -> [FormularyPreferenceView] {
        var views: [FormularyPreferenceView] = []
        for item in items {
            views.append(toFormularyPreferenceView(item))
        }
        return views
    }

    static func sumFormularyPreferenceView(_ view: FormularyPreferenceView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedBudget
    }
}
