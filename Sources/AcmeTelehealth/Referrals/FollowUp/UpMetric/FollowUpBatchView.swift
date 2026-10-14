import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up batch.
    final class FollowUpBatchView {
        var code: String
        var nameText: String
        var notes: String
        var archivedText: String
        var limit: String
        var attempts: String
        var statusLabel: String

        init(code: String, nameText: String, notes: String, archivedText: String, limit: String, attempts: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.notes = notes
            self.archivedText = archivedText
            self.limit = limit
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpBatchView(_ item: FollowUpBatch) -> FollowUpBatchView {
        return FollowUpBatchView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            notes: item.notes,
            archivedText: "\(item.archived)",
            limit: String(item.limit),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpBatchViews(_ items: [FollowUpBatch]) -> [FollowUpBatchView] {
        var views: [FollowUpBatchView] = []
        for item in items {
            views.append(toFollowUpBatchView(item))
        }
        return views
    }

    static func sumFollowUpBatchView(_ view: FollowUpBatchView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedLimit) + Double(parsedAttempts)
    }
}
