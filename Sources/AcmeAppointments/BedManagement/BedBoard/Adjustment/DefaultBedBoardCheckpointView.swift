import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a default bed board checkpoint.
    final class DefaultBedBoardCheckpointView {
        var code: String
        var name: String
        var titleText: String
        var descriptionText: String
        var externalRef: String
        var payer: String
        var quantity: String
        var reviewer: String
        var budget: String
        var label: String
        var statusLabel: String

        init(code: String, name: String, titleText: String, descriptionText: String, externalRef: String, payer: String, quantity: String, reviewer: String, budget: String, label: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.titleText = titleText
            self.descriptionText = descriptionText
            self.externalRef = externalRef
            self.payer = payer
            self.quantity = quantity
            self.reviewer = reviewer
            self.budget = budget
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultBedBoardCheckpointView(_ item: DefaultBedBoardCheckpoint) -> DefaultBedBoardCheckpointView {
        return DefaultBedBoardCheckpointView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            titleText: item.title,
            descriptionText: item.description,
            externalRef: item.externalRef,
            payer: item.payer,
            quantity: String(item.quantity),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 40),
            budget: String(format: "%.2f", item.budget),
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultBedBoardCheckpointViews(_ items: [DefaultBedBoardCheckpoint]) -> [DefaultBedBoardCheckpointView] {
        var views: [DefaultBedBoardCheckpointView] = []
        for item in items {
            views.append(toDefaultBedBoardCheckpointView(item))
        }
        return views
    }

    static func sumDefaultBedBoardCheckpointView(_ view: DefaultBedBoardCheckpointView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedQuantity) + parsedBudget
    }
}
