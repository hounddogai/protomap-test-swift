import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan batch.
    final class DischargePlanBatchView {
        var code: String
        var labelText: String
        var sequence: String
        var description: String
        var statusLabel: String

        init(code: String, labelText: String, sequence: String, description: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.sequence = sequence
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanBatchView(_ item: DischargePlanBatch) -> DischargePlanBatchView {
        return DischargePlanBatchView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            sequence: String(item.sequence),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanBatchViews(_ items: [DischargePlanBatch]) -> [DischargePlanBatchView] {
        var views: [DischargePlanBatchView] = []
        for item in items {
            views.append(toDischargePlanBatchView(item))
        }
        return views
    }

    static func sumDischargePlanBatchView(_ view: DischargePlanBatchView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedSequence)
    }
}
