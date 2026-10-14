import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched care gap digest.
    final class BatchedCareGapDigestView {
        var codeText: String
        var name: String
        var archived: String
        var wardText: String
        var ceilingText: String
        var statusLabel: String

        init(codeText: String, name: String, archived: String, wardText: String, ceilingText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.archived = archived
            self.wardText = wardText
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCareGapDigestView(_ item: BatchedCareGapDigest) -> BatchedCareGapDigestView {
        return BatchedCareGapDigestView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            archived: "\(item.archived)",
            wardText: Kit.Text.truncate(item.ward, limit: 120),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCareGapDigestViews(_ items: [BatchedCareGapDigest]) -> [BatchedCareGapDigestView] {
        var views: [BatchedCareGapDigestView] = []
        for item in items {
            views.append(toBatchedCareGapDigestView(item))
        }
        return views
    }

    static func sumBatchedCareGapDigestView(_ view: BatchedCareGapDigestView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
