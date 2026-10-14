import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a batched reference range window.
    final class BatchedReferenceRangeWindowView {
        var code: String
        var title: String
        var notes: String
        var batchSize: String
        var encounterID: String
        var acuity: String
        var revision: String
        var ceiling: String
        var statusLabel: String

        init(code: String, title: String, notes: String, batchSize: String, encounterID: String, acuity: String, revision: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notes = notes
            self.batchSize = batchSize
            self.encounterID = encounterID
            self.acuity = acuity
            self.revision = revision
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedReferenceRangeWindowView(_ item: BatchedReferenceRangeWindow) -> BatchedReferenceRangeWindowView {
        return BatchedReferenceRangeWindowView(
            code: item.code,
            title: item.title,
            notes: item.notes,
            batchSize: String(item.batchSize),
            encounterID: item.encounterID,
            acuity: String(item.acuity),
            revision: String(item.revision),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedReferenceRangeWindowViews(_ items: [BatchedReferenceRangeWindow]) -> [BatchedReferenceRangeWindowView] {
        var views: [BatchedReferenceRangeWindowView] = []
        for item in items {
            views.append(toBatchedReferenceRangeWindowView(item))
        }
        return views
    }

    static func sumBatchedReferenceRangeWindowView(_ view: BatchedReferenceRangeWindowView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedAcuity) + Double(parsedRevision)
    }
}
