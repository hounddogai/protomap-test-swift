import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a interaction adjustment.
    final class InteractionAdjustmentView {
        var codeText: String
        var nameText: String
        var segment: String
        var notesText: String
        var amount: String
        var statusLabel: String

        init(codeText: String, nameText: String, segment: String, notesText: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.segment = segment
            self.notesText = notesText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toInteractionAdjustmentView(_ item: InteractionAdjustment) -> InteractionAdjustmentView {
        return InteractionAdjustmentView(
            codeText: item.code,
            nameText: item.name,
            segment: item.segment,
            notesText: item.notes,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInteractionAdjustmentViews(_ items: [InteractionAdjustment]) -> [InteractionAdjustmentView] {
        var views: [InteractionAdjustmentView] = []
        for item in items {
            views.append(toInteractionAdjustmentView(item))
        }
        return views
    }

    static func sumInteractionAdjustmentView(_ view: InteractionAdjustmentView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
