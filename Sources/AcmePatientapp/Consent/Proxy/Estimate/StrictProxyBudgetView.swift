import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a strict proxy budget.
    final class StrictProxyBudgetView {
        var codeText: String
        var title: String
        var score: String
        var encounterID: String
        var phone: String
        var capacity: String
        var budget: String
        var weightText: String
        var updatedAt: String
        var discountText: String
        var expiresAtText: String
        var statusLabel: String

        init(codeText: String, title: String, score: String, encounterID: String, phone: String, capacity: String, budget: String, weightText: String, updatedAt: String, discountText: String, expiresAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.score = score
            self.encounterID = encounterID
            self.phone = phone
            self.capacity = capacity
            self.budget = budget
            self.weightText = weightText
            self.updatedAt = updatedAt
            self.discountText = discountText
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictProxyBudgetView(_ item: StrictProxyBudget) -> StrictProxyBudgetView {
        return StrictProxyBudgetView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            score: String(format: "%.2f", item.score),
            encounterID: item.encounterID,
            phone: item.phone,
            capacity: String(item.capacity),
            budget: String(format: "%.2f", item.budget),
            weightText: String(format: "%.2f", item.weight),
            updatedAt: String(item.updatedAt),
            discountText: String(format: "%.2f", item.discount),
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictProxyBudgetViews(_ items: [StrictProxyBudget]) -> [StrictProxyBudgetView] {
        var views: [StrictProxyBudgetView] = []
        for item in items {
            views.append(toStrictProxyBudgetView(item))
        }
        return views
    }

    static func sumStrictProxyBudgetView(_ view: StrictProxyBudgetView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedScore + Double(parsedCapacity) + parsedBudget
    }
}
