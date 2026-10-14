import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled worklist adjustment.
    final class ScheduledWorklistAdjustmentView {
        var code: String
        var label: String
        var specialtyText: String
        var unitText: String
        var copayText: String
        var procedureCodeText: String
        var batchSize: String
        var statusLabel: String

        init(code: String, label: String, specialtyText: String, unitText: String, copayText: String, procedureCodeText: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.specialtyText = specialtyText
            self.unitText = unitText
            self.copayText = copayText
            self.procedureCodeText = procedureCodeText
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledWorklistAdjustmentView(_ item: ScheduledWorklistAdjustment) -> ScheduledWorklistAdjustmentView {
        return ScheduledWorklistAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            specialtyText: item.specialty,
            unitText: item.unit,
            copayText: String(format: "%.2f", item.copay),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 80),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledWorklistAdjustmentViews(_ items: [ScheduledWorklistAdjustment]) -> [ScheduledWorklistAdjustmentView] {
        var views: [ScheduledWorklistAdjustmentView] = []
        for item in items {
            views.append(toScheduledWorklistAdjustmentView(item))
        }
        return views
    }

    static func sumScheduledWorklistAdjustmentView(_ view: ScheduledWorklistAdjustmentView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedCopay + Double(parsedBatchSize)
    }
}
