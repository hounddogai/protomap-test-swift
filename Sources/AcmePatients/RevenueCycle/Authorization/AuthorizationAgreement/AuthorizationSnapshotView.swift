import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization snapshot.
    final class AuthorizationSnapshotView {
        var codeText: String
        var name: String
        var categoryText: String
        var revisionText: String
        var bed: String
        var batchSize: String
        var summary: String
        var statusLabel: String

        init(codeText: String, name: String, categoryText: String, revisionText: String, bed: String, batchSize: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.categoryText = categoryText
            self.revisionText = revisionText
            self.bed = bed
            self.batchSize = batchSize
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationSnapshotView(_ item: AuthorizationSnapshot) -> AuthorizationSnapshotView {
        return AuthorizationSnapshotView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            categoryText: Kit.Text.truncate(item.category, limit: 120),
            revisionText: String(item.revision),
            bed: Kit.Text.truncate(item.bed, limit: 120),
            batchSize: String(item.batchSize),
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationSnapshotViews(_ items: [AuthorizationSnapshot]) -> [AuthorizationSnapshotView] {
        var views: [AuthorizationSnapshotView] = []
        for item in items {
            views.append(toAuthorizationSnapshotView(item))
        }
        return views
    }

    static func sumAuthorizationSnapshotView(_ view: AuthorizationSnapshotView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedRevision) + Double(parsedBatchSize)
    }
}
