import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a default result score.
    final class DefaultResultScoreView {
        var code: String
        var name: String
        var country: String
        var summary: String
        var localeText: String
        var budgetText: String
        var procedureCodeText: String
        var quantity: String
        var acuity: String
        var statusLabel: String

        init(code: String, name: String, country: String, summary: String, localeText: String, budgetText: String, procedureCodeText: String, quantity: String, acuity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.country = country
            self.summary = summary
            self.localeText = localeText
            self.budgetText = budgetText
            self.procedureCodeText = procedureCodeText
            self.quantity = quantity
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultResultScoreView(_ item: DefaultResultScore) -> DefaultResultScoreView {
        return DefaultResultScoreView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 80),
            country: item.country,
            summary: item.summary,
            localeText: item.locale,
            budgetText: String(format: "%.2f", item.budget),
            procedureCodeText: item.procedureCode,
            quantity: String(item.quantity),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultResultScoreViews(_ items: [DefaultResultScore]) -> [DefaultResultScoreView] {
        var views: [DefaultResultScoreView] = []
        for item in items {
            views.append(toDefaultResultScoreView(item))
        }
        return views
    }

    static func sumDefaultResultScoreView(_ view: DefaultResultScoreView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedBudget + Double(parsedQuantity) + Double(parsedAcuity)
    }
}
