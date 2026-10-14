import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel budget.
    final class PanelBudgetView {
        var codeText: String
        var titleText: String
        var expiresAt: String
        var name: String
        var visible: String
        var allergyText: String
        var ownerID: String
        var label: String
        var budget: String
        var statusLabel: String

        init(codeText: String, titleText: String, expiresAt: String, name: String, visible: String, allergyText: String, ownerID: String, label: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.expiresAt = expiresAt
            self.name = name
            self.visible = visible
            self.allergyText = allergyText
            self.ownerID = ownerID
            self.label = label
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toPanelBudgetView(_ item: PanelBudget) -> PanelBudgetView {
        return PanelBudgetView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            expiresAt: String(item.expiresAt),
            name: Kit.Text.truncate(item.name, limit: 80),
            visible: "\(item.visible)",
            allergyText: Kit.Text.truncate(item.allergy, limit: 40),
            ownerID: item.ownerID,
            label: Kit.Text.truncate(item.label, limit: 64),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelBudgetViews(_ items: [PanelBudget]) -> [PanelBudgetView] {
        var views: [PanelBudgetView] = []
        for item in items {
            views.append(toPanelBudgetView(item))
        }
        return views
    }

    static func sumPanelBudgetView(_ view: PanelBudgetView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedExpiresAt) + parsedBudget
    }
}
