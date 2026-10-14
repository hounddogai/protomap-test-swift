import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback discharge plan allocation.
    final class FallbackDischargePlanAllocationView {
        var code: String
        var label: String
        var discount: String
        var notes: String
        var minimum: String
        var approved: String
        var reviewer: String
        var statusLabel: String

        init(code: String, label: String, discount: String, notes: String, minimum: String, approved: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.discount = discount
            self.notes = notes
            self.minimum = minimum
            self.approved = approved
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackDischargePlanAllocationView(_ item: FallbackDischargePlanAllocation) -> FallbackDischargePlanAllocationView {
        return FallbackDischargePlanAllocationView(
            code: item.code,
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            notes: Kit.Text.truncate(item.notes, limit: 64),
            minimum: String(format: "%.2f", item.minimum),
            approved: "\(item.approved)",
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackDischargePlanAllocationViews(_ items: [FallbackDischargePlanAllocation]) -> [FallbackDischargePlanAllocationView] {
        var views: [FallbackDischargePlanAllocationView] = []
        for item in items {
            views.append(toFallbackDischargePlanAllocationView(item))
        }
        return views
    }

    static func sumFallbackDischargePlanAllocationView(_ view: FallbackDischargePlanAllocationView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedDiscount + parsedMinimum
    }
}
