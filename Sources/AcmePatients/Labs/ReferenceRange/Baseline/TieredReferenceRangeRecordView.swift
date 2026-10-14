import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a tiered reference range record.
    final class TieredReferenceRangeRecordView {
        var code: String
        var title: String
        var batchSize: String
        var priorityText: String
        var capacity: String
        var currency: String
        var summary: String
        var nameText: String
        var bedText: String
        var region: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, title: String, batchSize: String, priorityText: String, capacity: String, currency: String, summary: String, nameText: String, bedText: String, region: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.priorityText = priorityText
            self.capacity = capacity
            self.currency = currency
            self.summary = summary
            self.nameText = nameText
            self.bedText = bedText
            self.region = region
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toTieredReferenceRangeRecordView(_ item: TieredReferenceRangeRecord) -> TieredReferenceRangeRecordView {
        return TieredReferenceRangeRecordView(
            code: item.code,
            title: item.title,
            batchSize: String(item.batchSize),
            priorityText: String(item.priority),
            capacity: String(item.capacity),
            currency: item.currency,
            summary: item.summary,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            bedText: Kit.Text.truncate(item.bed, limit: 120),
            region: item.region,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredReferenceRangeRecordViews(_ items: [TieredReferenceRangeRecord]) -> [TieredReferenceRangeRecordView] {
        var views: [TieredReferenceRangeRecordView] = []
        for item in items {
            views.append(toTieredReferenceRangeRecordView(item))
        }
        return views
    }

    static func sumTieredReferenceRangeRecordView(_ view: TieredReferenceRangeRecordView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedPriority) + Double(parsedCapacity)
    }
}
