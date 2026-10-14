import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a batched reference range record.
    final class BatchedReferenceRangeRecordView {
        var code: String
        var titleText: String
        var approvedText: String
        var margin: String
        var ratioText: String
        var statusLabel: String

        init(code: String, titleText: String, approvedText: String, margin: String, ratioText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.approvedText = approvedText
            self.margin = margin
            self.ratioText = ratioText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedReferenceRangeRecordView(_ item: BatchedReferenceRangeRecord) -> BatchedReferenceRangeRecordView {
        return BatchedReferenceRangeRecordView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            approvedText: "\(item.approved)",
            margin: String(format: "%.2f", item.margin),
            ratioText: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedReferenceRangeRecordViews(_ items: [BatchedReferenceRangeRecord]) -> [BatchedReferenceRangeRecordView] {
        var views: [BatchedReferenceRangeRecordView] = []
        for item in items {
            views.append(toBatchedReferenceRangeRecordView(item))
        }
        return views
    }

    static func sumBatchedReferenceRangeRecordView(_ view: BatchedReferenceRangeRecordView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedMargin + parsedRatio
    }
}
