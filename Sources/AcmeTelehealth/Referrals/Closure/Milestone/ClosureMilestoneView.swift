import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure milestone.
    final class ClosureMilestoneView {
        var codeText: String
        var title: String
        var payerText: String
        var externalRef: String
        var name: String
        var scoreText: String
        var statusLabel: String

        init(codeText: String, title: String, payerText: String, externalRef: String, name: String, scoreText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.payerText = payerText
            self.externalRef = externalRef
            self.name = name
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toClosureMilestoneView(_ item: ClosureMilestone) -> ClosureMilestoneView {
        return ClosureMilestoneView(
            codeText: item.code,
            title: item.title,
            payerText: Kit.Text.truncate(item.payer, limit: 80),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            name: item.name,
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureMilestoneViews(_ items: [ClosureMilestone]) -> [ClosureMilestoneView] {
        var views: [ClosureMilestoneView] = []
        for item in items {
            views.append(toClosureMilestoneView(item))
        }
        return views
    }

    static func sumClosureMilestoneView(_ view: ClosureMilestoneView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
