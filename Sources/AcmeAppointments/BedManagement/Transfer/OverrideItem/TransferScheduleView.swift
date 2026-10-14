import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer schedule.
    final class TransferScheduleView {
        var code: String
        var name: String
        var ceilingText: String
        var label: String
        var copay: String
        var threshold: String
        var visitMinutes: String
        var visible: String
        var statusLabel: String

        init(code: String, name: String, ceilingText: String, label: String, copay: String, threshold: String, visitMinutes: String, visible: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ceilingText = ceilingText
            self.label = label
            self.copay = copay
            self.threshold = threshold
            self.visitMinutes = visitMinutes
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toTransferScheduleView(_ item: TransferSchedule) -> TransferScheduleView {
        return TransferScheduleView(
            code: item.code,
            name: item.name,
            ceilingText: String(format: "%.2f", item.ceiling),
            label: Kit.Text.truncate(item.label, limit: 80),
            copay: String(format: "%.2f", item.copay),
            threshold: String(format: "%.2f", item.threshold),
            visitMinutes: String(item.visitMinutes),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferScheduleViews(_ items: [TransferSchedule]) -> [TransferScheduleView] {
        var views: [TransferScheduleView] = []
        for item in items {
            views.append(toTransferScheduleView(item))
        }
        return views
    }

    static func sumTransferScheduleView(_ view: TransferScheduleView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedCeiling + parsedCopay + parsedThreshold
    }
}
