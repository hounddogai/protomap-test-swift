import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling care gap adjustment.
    final class RollingCareGapAdjustmentView {
        var codeText: String
        var label: String
        var timezoneText: String
        var notes: String
        var acuityText: String
        var checksum: String
        var priority: String
        var updatedAt: String
        var phone: String
        var summaryText: String
        var statusLabel: String

        init(codeText: String, label: String, timezoneText: String, notes: String, acuityText: String, checksum: String, priority: String, updatedAt: String, phone: String, summaryText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.timezoneText = timezoneText
            self.notes = notes
            self.acuityText = acuityText
            self.checksum = checksum
            self.priority = priority
            self.updatedAt = updatedAt
            self.phone = phone
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCareGapAdjustmentView(_ item: RollingCareGapAdjustment) -> RollingCareGapAdjustmentView {
        return RollingCareGapAdjustmentView(
            codeText: item.code,
            label: item.label,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 64),
            notes: item.notes,
            acuityText: String(item.acuity),
            checksum: Kit.Text.truncate(item.checksum, limit: 64),
            priority: String(item.priority),
            updatedAt: String(item.updatedAt),
            phone: Kit.Text.truncate(item.phone, limit: 80),
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCareGapAdjustmentViews(_ items: [RollingCareGapAdjustment]) -> [RollingCareGapAdjustmentView] {
        var views: [RollingCareGapAdjustmentView] = []
        for item in items {
            views.append(toRollingCareGapAdjustmentView(item))
        }
        return views
    }

    static func sumRollingCareGapAdjustmentView(_ view: RollingCareGapAdjustmentView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedAcuity) + Double(parsedPriority) + Double(parsedUpdatedAt)
    }
}
