import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a global slot adjustment.
    final class GlobalSlotAdjustmentView {
        var codeText: String
        var labelText: String
        var dosageMg: String
        var summary: String
        var capacity: String
        var thresholdText: String
        var amountText: String
        var ownerID: String
        var active: String
        var reviewer: String
        var statusLabel: String

        init(codeText: String, labelText: String, dosageMg: String, summary: String, capacity: String, thresholdText: String, amountText: String, ownerID: String, active: String, reviewer: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.dosageMg = dosageMg
            self.summary = summary
            self.capacity = capacity
            self.thresholdText = thresholdText
            self.amountText = amountText
            self.ownerID = ownerID
            self.active = active
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalSlotAdjustmentView(_ item: GlobalSlotAdjustment) -> GlobalSlotAdjustmentView {
        return GlobalSlotAdjustmentView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            dosageMg: String(format: "%.2f", item.dosageMg),
            summary: Kit.Text.truncate(item.summary, limit: 80),
            capacity: String(item.capacity),
            thresholdText: String(format: "%.2f", item.threshold),
            amountText: String(format: "%.2f", item.amount),
            ownerID: item.ownerID,
            active: "\(item.active)",
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalSlotAdjustmentViews(_ items: [GlobalSlotAdjustment]) -> [GlobalSlotAdjustmentView] {
        var views: [GlobalSlotAdjustmentView] = []
        for item in items {
            views.append(toGlobalSlotAdjustmentView(item))
        }
        return views
    }

    static func sumGlobalSlotAdjustmentView(_ view: GlobalSlotAdjustmentView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedDosageMg + Double(parsedCapacity) + parsedThreshold
    }
}
