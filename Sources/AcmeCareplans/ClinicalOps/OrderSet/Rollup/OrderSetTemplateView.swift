import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set template.
    final class OrderSetTemplateView {
        var codeText: String
        var label: String
        var createdAt: String
        var timezone: String
        var phone: String
        var budget: String
        var statusLabel: String

        init(codeText: String, label: String, createdAt: String, timezone: String, phone: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.createdAt = createdAt
            self.timezone = timezone
            self.phone = phone
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetTemplateView(_ item: OrderSetTemplate) -> OrderSetTemplateView {
        return OrderSetTemplateView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            createdAt: String(item.createdAt),
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            phone: item.phone,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetTemplateViews(_ items: [OrderSetTemplate]) -> [OrderSetTemplateView] {
        var views: [OrderSetTemplateView] = []
        for item in items {
            views.append(toOrderSetTemplateView(item))
        }
        return views
    }

    static func sumOrderSetTemplateView(_ view: OrderSetTemplateView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedCreatedAt) + parsedBudget
    }
}
