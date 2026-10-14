import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched authorization snapshot.
    final class BatchedAuthorizationSnapshotView {
        var codeText: String
        var title: String
        var contactEmail: String
        var reviewer: String
        var bed: String
        var scoreText: String
        var statusLabel: String

        init(codeText: String, title: String, contactEmail: String, reviewer: String, bed: String, scoreText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.contactEmail = contactEmail
            self.reviewer = reviewer
            self.bed = bed
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedAuthorizationSnapshotView(_ item: BatchedAuthorizationSnapshot) -> BatchedAuthorizationSnapshotView {
        return BatchedAuthorizationSnapshotView(
            codeText: item.code,
            title: item.title,
            contactEmail: item.contactEmail,
            reviewer: item.reviewer,
            bed: Kit.Text.truncate(item.bed, limit: 120),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedAuthorizationSnapshotViews(_ items: [BatchedAuthorizationSnapshot]) -> [BatchedAuthorizationSnapshotView] {
        var views: [BatchedAuthorizationSnapshotView] = []
        for item in items {
            views.append(toBatchedAuthorizationSnapshotView(item))
        }
        return views
    }

    static func sumBatchedAuthorizationSnapshotView(_ view: BatchedAuthorizationSnapshotView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
