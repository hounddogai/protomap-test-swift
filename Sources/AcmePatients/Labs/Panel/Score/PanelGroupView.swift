import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel group.
    final class PanelGroupView {
        var code: String
        var name: String
        var category: String
        var amount: String
        var limitText: String
        var refills: String
        var budget: String
        var statusLabel: String

        init(code: String, name: String, category: String, amount: String, limitText: String, refills: String, budget: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.category = category
            self.amount = amount
            self.limitText = limitText
            self.refills = refills
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toPanelGroupView(_ item: PanelGroup) -> PanelGroupView {
        return PanelGroupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            category: Kit.Text.truncate(item.category, limit: 120),
            amount: String(format: "%.2f", item.amount),
            limitText: String(item.limit),
            refills: String(item.refills),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelGroupViews(_ items: [PanelGroup]) -> [PanelGroupView] {
        var views: [PanelGroupView] = []
        for item in items {
            views.append(toPanelGroupView(item))
        }
        return views
    }

    static func sumPanelGroupView(_ view: PanelGroupView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedAmount + Double(parsedLimit) + Double(parsedRefills)
    }
}
