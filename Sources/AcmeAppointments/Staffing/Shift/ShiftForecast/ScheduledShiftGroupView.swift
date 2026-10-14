import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a scheduled shift group.
    final class ScheduledShiftGroupView {
        var codeText: String
        var labelText: String
        var pinned: String
        var batchSize: String
        var durationMinutesText: String
        var copayText: String
        var payer: String
        var statusLabel: String

        init(codeText: String, labelText: String, pinned: String, batchSize: String, durationMinutesText: String, copayText: String, payer: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.pinned = pinned
            self.batchSize = batchSize
            self.durationMinutesText = durationMinutesText
            self.copayText = copayText
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledShiftGroupView(_ item: ScheduledShiftGroup) -> ScheduledShiftGroupView {
        return ScheduledShiftGroupView(
            codeText: item.code,
            labelText: item.label,
            pinned: "\(item.pinned)",
            batchSize: String(item.batchSize),
            durationMinutesText: String(item.durationMinutes),
            copayText: String(format: "%.2f", item.copay),
            payer: Kit.Text.truncate(item.payer, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledShiftGroupViews(_ items: [ScheduledShiftGroup]) -> [ScheduledShiftGroupView] {
        var views: [ScheduledShiftGroupView] = []
        for item in items {
            views.append(toScheduledShiftGroupView(item))
        }
        return views
    }

    static func sumScheduledShiftGroupView(_ view: ScheduledShiftGroupView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedDurationMinutes) + parsedCopay
    }
}
