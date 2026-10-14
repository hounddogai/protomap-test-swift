import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched care gap assignment.
    final class BatchedCareGapAssignmentView {
        var codeText: String
        var title: String
        var visitMinutes: String
        var source: String
        var reviewer: String
        var summary: String
        var payer: String
        var revision: String
        var retries: String
        var statusLabel: String

        init(codeText: String, title: String, visitMinutes: String, source: String, reviewer: String, summary: String, payer: String, revision: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.visitMinutes = visitMinutes
            self.source = source
            self.reviewer = reviewer
            self.summary = summary
            self.payer = payer
            self.revision = revision
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCareGapAssignmentView(_ item: BatchedCareGapAssignment) -> BatchedCareGapAssignmentView {
        return BatchedCareGapAssignmentView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            visitMinutes: String(item.visitMinutes),
            source: item.source,
            reviewer: item.reviewer,
            summary: item.summary,
            payer: item.payer,
            revision: String(item.revision),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCareGapAssignmentViews(_ items: [BatchedCareGapAssignment]) -> [BatchedCareGapAssignmentView] {
        var views: [BatchedCareGapAssignmentView] = []
        for item in items {
            views.append(toBatchedCareGapAssignmentView(item))
        }
        return views
    }

    static func sumBatchedCareGapAssignmentView(_ view: BatchedCareGapAssignmentView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedRevision) + Double(parsedRetries)
    }
}
