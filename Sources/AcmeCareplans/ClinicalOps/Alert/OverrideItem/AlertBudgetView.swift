import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert budget.
    final class AlertBudgetView {
        var code: String
        var title: String
        var createdAtText: String
        var notesText: String
        var ceiling: String
        var segment: String
        var discountText: String
        var reviewer: String
        var endsAt: String
        var statusLabel: String

        init(code: String, title: String, createdAtText: String, notesText: String, ceiling: String, segment: String, discountText: String, reviewer: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.createdAtText = createdAtText
            self.notesText = notesText
            self.ceiling = ceiling
            self.segment = segment
            self.discountText = discountText
            self.reviewer = reviewer
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toAlertBudgetView(_ item: AlertBudget) -> AlertBudgetView {
        return AlertBudgetView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            createdAtText: String(item.createdAt),
            notesText: Kit.Text.truncate(item.notes, limit: 40),
            ceiling: String(format: "%.2f", item.ceiling),
            segment: item.segment,
            discountText: String(format: "%.2f", item.discount),
            reviewer: item.reviewer,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertBudgetViews(_ items: [AlertBudget]) -> [AlertBudgetView] {
        var views: [AlertBudgetView] = []
        for item in items {
            views.append(toAlertBudgetView(item))
        }
        return views
    }

    static func sumAlertBudgetView(_ view: AlertBudgetView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedCreatedAt) + parsedCeiling + parsedDiscount
    }
}
