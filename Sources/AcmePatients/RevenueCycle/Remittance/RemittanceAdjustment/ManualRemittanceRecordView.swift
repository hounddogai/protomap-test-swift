import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual remittance record.
    final class ManualRemittanceRecordView {
        var code: String
        var name: String
        var batchSize: String
        var graceDays: String
        var summary: String
        var procedureCodeText: String
        var description: String
        var statusLabel: String

        init(code: String, name: String, batchSize: String, graceDays: String, summary: String, procedureCodeText: String, description: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.summary = summary
            self.procedureCodeText = procedureCodeText
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toManualRemittanceRecordView(_ item: ManualRemittanceRecord) -> ManualRemittanceRecordView {
        return ManualRemittanceRecordView(
            code: item.code,
            name: item.name,
            batchSize: String(item.batchSize),
            graceDays: String(item.graceDays),
            summary: item.summary,
            procedureCodeText: item.procedureCode,
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualRemittanceRecordViews(_ items: [ManualRemittanceRecord]) -> [ManualRemittanceRecordView] {
        var views: [ManualRemittanceRecordView] = []
        for item in items {
            views.append(toManualRemittanceRecordView(item))
        }
        return views
    }

    static func sumManualRemittanceRecordView(_ view: ManualRemittanceRecordView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedGraceDays)
    }
}
