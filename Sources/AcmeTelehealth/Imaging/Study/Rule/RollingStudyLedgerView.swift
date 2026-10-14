import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling study ledger.
    final class RollingStudyLedgerView {
        var code: String
        var label: String
        var copay: String
        var durationMinutes: String
        var batchSizeText: String
        var threshold: String
        var capacity: String
        var discount: String
        var statusLabel: String

        init(code: String, label: String, copay: String, durationMinutes: String, batchSizeText: String, threshold: String, capacity: String, discount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.copay = copay
            self.durationMinutes = durationMinutes
            self.batchSizeText = batchSizeText
            self.threshold = threshold
            self.capacity = capacity
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toRollingStudyLedgerView(_ item: RollingStudyLedger) -> RollingStudyLedgerView {
        return RollingStudyLedgerView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            copay: String(format: "%.2f", item.copay),
            durationMinutes: String(item.durationMinutes),
            batchSizeText: String(item.batchSize),
            threshold: String(format: "%.2f", item.threshold),
            capacity: String(item.capacity),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingStudyLedgerViews(_ items: [RollingStudyLedger]) -> [RollingStudyLedgerView] {
        var views: [RollingStudyLedgerView] = []
        for item in items {
            views.append(toRollingStudyLedgerView(item))
        }
        return views
    }

    static func sumRollingStudyLedgerView(_ view: RollingStudyLedgerView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedCopay + Double(parsedDurationMinutes) + Double(parsedBatchSize)
    }
}
