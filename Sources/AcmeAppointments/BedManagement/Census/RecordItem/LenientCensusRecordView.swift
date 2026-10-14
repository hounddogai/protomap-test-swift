import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient census record.
    final class LenientCensusRecordView {
        var code: String
        var label: String
        var batchSize: String
        var timezoneText: String
        var copay: String
        var statusLabel: String

        init(code: String, label: String, batchSize: String, timezoneText: String, copay: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.timezoneText = timezoneText
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCensusRecordView(_ item: LenientCensusRecord) -> LenientCensusRecordView {
        return LenientCensusRecordView(
            code: item.code,
            label: item.label,
            batchSize: String(item.batchSize),
            timezoneText: item.timezone,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCensusRecordViews(_ items: [LenientCensusRecord]) -> [LenientCensusRecordView] {
        var views: [LenientCensusRecordView] = []
        for item in items {
            views.append(toLenientCensusRecordView(item))
        }
        return views
    }

    static func sumLenientCensusRecordView(_ view: LenientCensusRecordView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedBatchSize) + parsedCopay
    }
}
