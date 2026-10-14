import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction allocation.
    final class InteractionAllocationView {
        var code: String
        var nameText: String
        var sequence: String
        var cost: String
        var approved: String
        var reviewer: String
        var statusLabel: String

        init(code: String, nameText: String, sequence: String, cost: String, approved: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.sequence = sequence
            self.cost = cost
            self.approved = approved
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionAllocationView(_ item: InteractionAllocation) -> InteractionAllocationView {
        return InteractionAllocationView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            sequence: String(item.sequence),
            cost: String(format: "%.2f", item.cost),
            approved: "\(item.approved)",
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionAllocationViews(_ items: [InteractionAllocation]) -> [InteractionAllocationView] {
        var views: [InteractionAllocationView] = []
        for item in items {
            views.append(toInteractionAllocationView(item))
        }
        return views
    }

    static func sumInteractionAllocationView(_ view: InteractionAllocationView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedSequence) + parsedCost
    }
}
