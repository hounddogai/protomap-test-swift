import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff policy.
    final class HandoffPolicyView {
        var code: String
        var title: String
        var procedureCodeText: String
        var label: String
        var source: String
        var scoreText: String
        var ratio: String
        var pinned: String
        var sequence: String
        var active: String
        var statusLabel: String

        init(code: String, title: String, procedureCodeText: String, label: String, source: String, scoreText: String, ratio: String, pinned: String, sequence: String, active: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCodeText = procedureCodeText
            self.label = label
            self.source = source
            self.scoreText = scoreText
            self.ratio = ratio
            self.pinned = pinned
            self.sequence = sequence
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffPolicyView(_ item: HandoffPolicy) -> HandoffPolicyView {
        return HandoffPolicyView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 120),
            procedureCodeText: item.procedureCode,
            label: item.label,
            source: item.source,
            scoreText: String(format: "%.2f", item.score),
            ratio: String(format: "%.2f", item.ratio),
            pinned: "\(item.pinned)",
            sequence: String(item.sequence),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffPolicyViews(_ items: [HandoffPolicy]) -> [HandoffPolicyView] {
        var views: [HandoffPolicyView] = []
        for item in items {
            views.append(toHandoffPolicyView(item))
        }
        return views
    }

    static func sumHandoffPolicyView(_ view: HandoffPolicyView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedScore + parsedRatio + Double(parsedSequence)
    }
}
