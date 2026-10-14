import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a primary goal proposal.
    final class PrimaryGoalProposalView {
        var codeText: String
        var label: String
        var maximumText: String
        var createdAt: String
        var quantity: String
        var visitMinutesText: String
        var durationMinutes: String
        var priority: String
        var capacity: String
        var ratio: String
        var statusLabel: String

        init(codeText: String, label: String, maximumText: String, createdAt: String, quantity: String, visitMinutesText: String, durationMinutes: String, priority: String, capacity: String, ratio: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.maximumText = maximumText
            self.createdAt = createdAt
            self.quantity = quantity
            self.visitMinutesText = visitMinutesText
            self.durationMinutes = durationMinutes
            self.priority = priority
            self.capacity = capacity
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryGoalProposalView(_ item: PrimaryGoalProposal) -> PrimaryGoalProposalView {
        return PrimaryGoalProposalView(
            codeText: item.code,
            label: item.label,
            maximumText: String(format: "%.2f", item.maximum),
            createdAt: String(item.createdAt),
            quantity: String(item.quantity),
            visitMinutesText: String(item.visitMinutes),
            durationMinutes: String(item.durationMinutes),
            priority: String(item.priority),
            capacity: String(item.capacity),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryGoalProposalViews(_ items: [PrimaryGoalProposal]) -> [PrimaryGoalProposalView] {
        var views: [PrimaryGoalProposalView] = []
        for item in items {
            views.append(toPrimaryGoalProposalView(item))
        }
        return views
    }

    static func sumPrimaryGoalProposalView(_ view: PrimaryGoalProposalView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedMaximum + Double(parsedCreatedAt) + Double(parsedQuantity)
    }
}
