import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census score.
    final class CensusScoreView {
        var code: String
        var label: String
        var budget: String
        var archived: String
        var revisionText: String
        var attempts: String
        var sequenceText: String
        var priority: String
        var segmentText: String
        var acuityText: String
        var statusLabel: String

        init(code: String, label: String, budget: String, archived: String, revisionText: String, attempts: String, sequenceText: String, priority: String, segmentText: String, acuityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.budget = budget
            self.archived = archived
            self.revisionText = revisionText
            self.attempts = attempts
            self.sequenceText = sequenceText
            self.priority = priority
            self.segmentText = segmentText
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toCensusScoreView(_ item: CensusScore) -> CensusScoreView {
        return CensusScoreView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            budget: String(format: "%.2f", item.budget),
            archived: "\(item.archived)",
            revisionText: String(item.revision),
            attempts: String(item.attempts),
            sequenceText: String(item.sequence),
            priority: String(item.priority),
            segmentText: Kit.Text.truncate(item.segment, limit: 40),
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusScoreViews(_ items: [CensusScore]) -> [CensusScoreView] {
        var views: [CensusScoreView] = []
        for item in items {
            views.append(toCensusScoreView(item))
        }
        return views
    }

    static func sumCensusScoreView(_ view: CensusScoreView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedBudget + Double(parsedRevision) + Double(parsedAttempts)
    }
}
