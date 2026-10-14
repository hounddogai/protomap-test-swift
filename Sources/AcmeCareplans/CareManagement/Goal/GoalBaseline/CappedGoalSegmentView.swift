import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a capped goal segment.
    final class CappedGoalSegmentView {
        var code: String
        var title: String
        var updatedAt: String
        var bed: String
        var checksum: String
        var batchSize: String
        var statusLabel: String

        init(code: String, title: String, updatedAt: String, bed: String, checksum: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.bed = bed
            self.checksum = checksum
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toCappedGoalSegmentView(_ item: CappedGoalSegment) -> CappedGoalSegmentView {
        return CappedGoalSegmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            updatedAt: String(item.updatedAt),
            bed: Kit.Text.truncate(item.bed, limit: 120),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedGoalSegmentViews(_ items: [CappedGoalSegment]) -> [CappedGoalSegmentView] {
        var views: [CappedGoalSegmentView] = []
        for item in items {
            views.append(toCappedGoalSegmentView(item))
        }
        return views
    }

    static func sumCappedGoalSegmentView(_ view: CappedGoalSegmentView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedBatchSize)
    }
}
