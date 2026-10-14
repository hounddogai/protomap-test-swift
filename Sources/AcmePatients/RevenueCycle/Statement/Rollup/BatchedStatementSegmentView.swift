import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched statement segment.
    final class BatchedStatementSegmentView {
        var code: String
        var nameText: String
        var reviewerText: String
        var priority: String
        var windowDays: String
        var acuity: String
        var segmentText: String
        var statusLabel: String

        init(code: String, nameText: String, reviewerText: String, priority: String, windowDays: String, acuity: String, segmentText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.reviewerText = reviewerText
            self.priority = priority
            self.windowDays = windowDays
            self.acuity = acuity
            self.segmentText = segmentText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedStatementSegmentView(_ item: BatchedStatementSegment) -> BatchedStatementSegmentView {
        return BatchedStatementSegmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 120),
            priority: String(item.priority),
            windowDays: String(item.windowDays),
            acuity: String(item.acuity),
            segmentText: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedStatementSegmentViews(_ items: [BatchedStatementSegment]) -> [BatchedStatementSegmentView] {
        var views: [BatchedStatementSegmentView] = []
        for item in items {
            views.append(toBatchedStatementSegmentView(item))
        }
        return views
    }

    static func sumBatchedStatementSegmentView(_ view: BatchedStatementSegmentView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedPriority) + Double(parsedWindowDays) + Double(parsedAcuity)
    }
}
