import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending eligibility slot.
    final class PendingEligibilitySlotView {
        var codeText: String
        var title: String
        var procedureCode: String
        var labelText: String
        var minimum: String
        var floorValue: String
        var country: String
        var updatedAtText: String
        var statusLabel: String

        init(codeText: String, title: String, procedureCode: String, labelText: String, minimum: String, floorValue: String, country: String, updatedAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.procedureCode = procedureCode
            self.labelText = labelText
            self.minimum = minimum
            self.floorValue = floorValue
            self.country = country
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingEligibilitySlotView(_ item: PendingEligibilitySlot) -> PendingEligibilitySlotView {
        return PendingEligibilitySlotView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            procedureCode: item.procedureCode,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            floorValue: String(format: "%.2f", item.floorValue),
            country: item.country,
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingEligibilitySlotViews(_ items: [PendingEligibilitySlot]) -> [PendingEligibilitySlotView] {
        var views: [PendingEligibilitySlotView] = []
        for item in items {
            views.append(toPendingEligibilitySlotView(item))
        }
        return views
    }

    static func sumPendingEligibilitySlotView(_ view: PendingEligibilitySlotView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedMinimum + parsedFloorValue + Double(parsedUpdatedAt)
    }
}
