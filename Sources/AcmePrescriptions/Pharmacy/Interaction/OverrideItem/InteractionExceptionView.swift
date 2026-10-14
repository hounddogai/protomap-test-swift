import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction exception.
    final class InteractionExceptionView {
        var code: String
        var labelText: String
        var ownerID: String
        var createdAt: String
        var title: String
        var budget: String
        var approved: String
        var ceiling: String
        var statusLabel: String

        init(code: String, labelText: String, ownerID: String, createdAt: String, title: String, budget: String, approved: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.ownerID = ownerID
            self.createdAt = createdAt
            self.title = title
            self.budget = budget
            self.approved = approved
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionExceptionView(_ item: InteractionException) -> InteractionExceptionView {
        return InteractionExceptionView(
            code: item.code,
            labelText: item.label,
            ownerID: item.ownerID,
            createdAt: String(item.createdAt),
            title: item.title,
            budget: String(format: "%.2f", item.budget),
            approved: "\(item.approved)",
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionExceptionViews(_ items: [InteractionException]) -> [InteractionExceptionView] {
        var views: [InteractionExceptionView] = []
        for item in items {
            views.append(toInteractionExceptionView(item))
        }
        return views
    }

    static func sumInteractionExceptionView(_ view: InteractionExceptionView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedCreatedAt) + parsedBudget + parsedCeiling
    }
}
