import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a rolling claim override.
    final class RollingClaimOverrideView {
        var codeText: String
        var title: String
        var activeText: String
        var archived: String
        var channelText: String
        var payer: String
        var encounterID: String
        var scoreText: String
        var statusLabel: String

        init(codeText: String, title: String, activeText: String, archived: String, channelText: String, payer: String, encounterID: String, scoreText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.activeText = activeText
            self.archived = archived
            self.channelText = channelText
            self.payer = payer
            self.encounterID = encounterID
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingClaimOverrideView(_ item: RollingClaimOverride) -> RollingClaimOverrideView {
        return RollingClaimOverrideView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            activeText: "\(item.active)",
            archived: "\(item.archived)",
            channelText: Kit.Text.truncate(item.channel, limit: 40),
            payer: item.payer,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingClaimOverrideViews(_ items: [RollingClaimOverride]) -> [RollingClaimOverrideView] {
        var views: [RollingClaimOverrideView] = []
        for item in items {
            views.append(toRollingClaimOverrideView(item))
        }
        return views
    }

    static func sumRollingClaimOverrideView(_ view: RollingClaimOverrideView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
