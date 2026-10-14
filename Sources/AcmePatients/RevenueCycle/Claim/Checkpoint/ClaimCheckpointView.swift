import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim checkpoint.
    final class ClaimCheckpointView {
        var code: String
        var name: String
        var batchSize: String
        var endsAt: String
        var pinned: String
        var statusLabel: String

        init(code: String, name: String, batchSize: String, endsAt: String, pinned: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.endsAt = endsAt
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toClaimCheckpointView(_ item: ClaimCheckpoint) -> ClaimCheckpointView {
        return ClaimCheckpointView(
            code: item.code,
            name: item.name,
            batchSize: String(item.batchSize),
            endsAt: String(item.endsAt),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimCheckpointViews(_ items: [ClaimCheckpoint]) -> [ClaimCheckpointView] {
        var views: [ClaimCheckpointView] = []
        for item in items {
            views.append(toClaimCheckpointView(item))
        }
        return views
    }

    static func sumClaimCheckpointView(_ view: ClaimCheckpointView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedEndsAt)
    }
}
