import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched witness adjustment.
    final class BatchedWitnessAdjustmentView {
        var code: String
        var label: String
        var graceDaysText: String
        var unitText: String
        var maximum: String
        var statusLabel: String

        init(code: String, label: String, graceDaysText: String, unitText: String, maximum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.graceDaysText = graceDaysText
            self.unitText = unitText
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedWitnessAdjustmentView(_ item: BatchedWitnessAdjustment) -> BatchedWitnessAdjustmentView {
        return BatchedWitnessAdjustmentView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            graceDaysText: String(item.graceDays),
            unitText: item.unit,
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedWitnessAdjustmentViews(_ items: [BatchedWitnessAdjustment]) -> [BatchedWitnessAdjustmentView] {
        var views: [BatchedWitnessAdjustmentView] = []
        for item in items {
            views.append(toBatchedWitnessAdjustmentView(item))
        }
        return views
    }

    static func sumBatchedWitnessAdjustmentView(_ view: BatchedWitnessAdjustmentView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedGraceDays) + parsedMaximum
    }
}
