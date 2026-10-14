import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled transfer adjustment.
    final class ScheduledTransferAdjustmentView {
        var code: String
        var label: String
        var patientRef: String
        var externalRef: String
        var channel: String
        var discount: String
        var createdAt: String
        var segment: String
        var statusLabel: String

        init(code: String, label: String, patientRef: String, externalRef: String, channel: String, discount: String, createdAt: String, segment: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.externalRef = externalRef
            self.channel = channel
            self.discount = discount
            self.createdAt = createdAt
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledTransferAdjustmentView(_ item: ScheduledTransferAdjustment) -> ScheduledTransferAdjustmentView {
        return ScheduledTransferAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 64),
            externalRef: item.externalRef,
            channel: item.channel,
            discount: String(format: "%.2f", item.discount),
            createdAt: String(item.createdAt),
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledTransferAdjustmentViews(_ items: [ScheduledTransferAdjustment]) -> [ScheduledTransferAdjustmentView] {
        var views: [ScheduledTransferAdjustmentView] = []
        for item in items {
            views.append(toScheduledTransferAdjustmentView(item))
        }
        return views
    }

    static func sumScheduledTransferAdjustmentView(_ view: ScheduledTransferAdjustmentView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedDiscount + Double(parsedCreatedAt)
    }
}
