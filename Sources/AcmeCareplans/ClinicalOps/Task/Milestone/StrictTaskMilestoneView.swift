import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a strict task milestone.
    final class StrictTaskMilestoneView {
        var codeText: String
        var titleText: String
        var attempts: String
        var checksum: String
        var scoreText: String
        var statusLabel: String

        init(codeText: String, titleText: String, attempts: String, checksum: String, scoreText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.attempts = attempts
            self.checksum = checksum
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictTaskMilestoneView(_ item: StrictTaskMilestone) -> StrictTaskMilestoneView {
        return StrictTaskMilestoneView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            attempts: String(item.attempts),
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictTaskMilestoneViews(_ items: [StrictTaskMilestone]) -> [StrictTaskMilestoneView] {
        var views: [StrictTaskMilestoneView] = []
        for item in items {
            views.append(toStrictTaskMilestoneView(item))
        }
        return views
    }

    static func sumStrictTaskMilestoneView(_ view: StrictTaskMilestoneView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedAttempts) + parsedScore
    }
}
