import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped follow up checkpoint.
    final class CappedFollowUpCheckpointView {
        var code: String
        var title: String
        var ceiling: String
        var channel: String
        var timezone: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, ceiling: String, channel: String, timezone: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.channel = channel
            self.timezone = timezone
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toCappedFollowUpCheckpointView(_ item: CappedFollowUpCheckpoint) -> CappedFollowUpCheckpointView {
        return CappedFollowUpCheckpointView(
            code: item.code,
            title: item.title,
            ceiling: String(format: "%.2f", item.ceiling),
            channel: item.channel,
            timezone: Kit.Text.truncate(item.timezone, limit: 64),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedFollowUpCheckpointViews(_ items: [CappedFollowUpCheckpoint]) -> [CappedFollowUpCheckpointView] {
        var views: [CappedFollowUpCheckpointView] = []
        for item in items {
            views.append(toCappedFollowUpCheckpointView(item))
        }
        return views
    }

    static func sumCappedFollowUpCheckpointView(_ view: CappedFollowUpCheckpointView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedCeiling + parsedScore
    }
}
