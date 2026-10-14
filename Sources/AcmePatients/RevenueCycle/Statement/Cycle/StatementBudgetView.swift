import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement budget.
    final class StatementBudgetView {
        var codeText: String
        var title: String
        var payer: String
        var rateText: String
        var allergy: String
        var visibleText: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, title: String, payer: String, rateText: String, allergy: String, visibleText: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.payer = payer
            self.rateText = rateText
            self.allergy = allergy
            self.visibleText = visibleText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toStatementBudgetView(_ item: StatementBudget) -> StatementBudgetView {
        return StatementBudgetView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            payer: item.payer,
            rateText: String(format: "%.2f", item.rate),
            allergy: Kit.Text.truncate(item.allergy, limit: 64),
            visibleText: "\(item.visible)",
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementBudgetViews(_ items: [StatementBudget]) -> [StatementBudgetView] {
        var views: [StatementBudgetView] = []
        for item in items {
            views.append(toStatementBudgetView(item))
        }
        return views
    }

    static func sumStatementBudgetView(_ view: StatementBudgetView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedRate + parsedFloorValue
    }
}
