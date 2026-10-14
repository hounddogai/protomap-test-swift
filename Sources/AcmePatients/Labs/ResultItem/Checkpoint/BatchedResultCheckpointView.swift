import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a batched result checkpoint.
    final class BatchedResultCheckpointView {
        var code: String
        var titleText: String
        var patientRef: String
        var batchSizeText: String
        var country: String
        var graceDays: String
        var statusLabel: String

        init(code: String, titleText: String, patientRef: String, batchSizeText: String, country: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.patientRef = patientRef
            self.batchSizeText = batchSizeText
            self.country = country
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedResultCheckpointView(_ item: BatchedResultCheckpoint) -> BatchedResultCheckpointView {
        return BatchedResultCheckpointView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            patientRef: item.patientRef,
            batchSizeText: String(item.batchSize),
            country: item.country,
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedResultCheckpointViews(_ items: [BatchedResultCheckpoint]) -> [BatchedResultCheckpointView] {
        var views: [BatchedResultCheckpointView] = []
        for item in items {
            views.append(toBatchedResultCheckpointView(item))
        }
        return views
    }

    static func sumBatchedResultCheckpointView(_ view: BatchedResultCheckpointView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedGraceDays)
    }
}
