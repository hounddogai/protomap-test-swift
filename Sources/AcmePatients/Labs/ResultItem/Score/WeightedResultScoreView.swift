import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted result score.
    final class WeightedResultScoreView {
        var codeText: String
        var name: String
        var timezone: String
        var scoreText: String
        var quantity: String
        var sequenceText: String
        var statusLabel: String

        init(codeText: String, name: String, timezone: String, scoreText: String, quantity: String, sequenceText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.timezone = timezone
            self.scoreText = scoreText
            self.quantity = quantity
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedResultScoreView(_ item: WeightedResultScore) -> WeightedResultScoreView {
        return WeightedResultScoreView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            timezone: item.timezone,
            scoreText: String(format: "%.2f", item.score),
            quantity: String(item.quantity),
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedResultScoreViews(_ items: [WeightedResultScore]) -> [WeightedResultScoreView] {
        var views: [WeightedResultScoreView] = []
        for item in items {
            views.append(toWeightedResultScoreView(item))
        }
        return views
    }

    static func sumWeightedResultScoreView(_ view: WeightedResultScoreView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedScore + Double(parsedQuantity) + Double(parsedSequence)
    }
}
