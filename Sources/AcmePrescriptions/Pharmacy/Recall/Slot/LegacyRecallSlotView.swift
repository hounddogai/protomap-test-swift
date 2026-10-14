import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy recall slot.
    final class LegacyRecallSlotView {
        var code: String
        var name: String
        var specialty: String
        var budgetText: String
        var segment: String
        var approvedText: String
        var statusLabel: String

        init(code: String, name: String, specialty: String, budgetText: String, segment: String, approvedText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.budgetText = budgetText
            self.segment = segment
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyRecallSlotView(_ item: LegacyRecallSlot) -> LegacyRecallSlotView {
        return LegacyRecallSlotView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            specialty: item.specialty,
            budgetText: String(format: "%.2f", item.budget),
            segment: item.segment,
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyRecallSlotViews(_ items: [LegacyRecallSlot]) -> [LegacyRecallSlotView] {
        var views: [LegacyRecallSlotView] = []
        for item in items {
            views.append(toLegacyRecallSlotView(item))
        }
        return views
    }

    static func sumLegacyRecallSlotView(_ view: LegacyRecallSlotView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedBudget
    }
}
