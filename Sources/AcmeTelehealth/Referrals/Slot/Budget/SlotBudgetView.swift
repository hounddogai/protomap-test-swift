import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot budget.
    final class SlotBudgetView {
        var codeText: String
        var titleText: String
        var threshold: String
        var priorityText: String
        var createdAt: String
        var currency: String
        var durationMinutes: String
        var discountText: String
        var statusLabel: String

        init(codeText: String, titleText: String, threshold: String, priorityText: String, createdAt: String, currency: String, durationMinutes: String, discountText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.threshold = threshold
            self.priorityText = priorityText
            self.createdAt = createdAt
            self.currency = currency
            self.durationMinutes = durationMinutes
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotBudgetView(_ item: SlotBudget) -> SlotBudgetView {
        return SlotBudgetView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            threshold: String(format: "%.2f", item.threshold),
            priorityText: String(item.priority),
            createdAt: String(item.createdAt),
            currency: item.currency,
            durationMinutes: String(item.durationMinutes),
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotBudgetViews(_ items: [SlotBudget]) -> [SlotBudgetView] {
        var views: [SlotBudgetView] = []
        for item in items {
            views.append(toSlotBudgetView(item))
        }
        return views
    }

    static func sumSlotBudgetView(_ view: SlotBudgetView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedThreshold + Double(parsedPriority) + Double(parsedCreatedAt)
    }
}
