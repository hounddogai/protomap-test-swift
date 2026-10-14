import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language budget.
    final class LanguageBudgetView {
        var codeText: String
        var name: String
        var patientRef: String
        var currencyText: String
        var limitText: String
        var visible: String
        var quantity: String
        var minimumText: String
        var statusLabel: String

        init(codeText: String, name: String, patientRef: String, currencyText: String, limitText: String, visible: String, quantity: String, minimumText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.patientRef = patientRef
            self.currencyText = currencyText
            self.limitText = limitText
            self.visible = visible
            self.quantity = quantity
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageBudgetView(_ item: LanguageBudget) -> LanguageBudgetView {
        return LanguageBudgetView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            patientRef: item.patientRef,
            currencyText: Kit.Text.truncate(item.currency, limit: 80),
            limitText: String(item.limit),
            visible: "\(item.visible)",
            quantity: String(item.quantity),
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageBudgetViews(_ items: [LanguageBudget]) -> [LanguageBudgetView] {
        var views: [LanguageBudgetView] = []
        for item in items {
            views.append(toLanguageBudgetView(item))
        }
        return views
    }

    static func sumLanguageBudgetView(_ view: LanguageBudgetView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedLimit) + Double(parsedQuantity) + parsedMinimum
    }
}
