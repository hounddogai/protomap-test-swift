import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary handoff cycle.
    final class PrimaryHandoffCycleView {
        var code: String
        var labelText: String
        var priority: String
        var scoreText: String
        var ownerIDText: String
        var statusLabel: String

        init(code: String, labelText: String, priority: String, scoreText: String, ownerIDText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.priority = priority
            self.scoreText = scoreText
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryHandoffCycleView(_ item: PrimaryHandoffCycle) -> PrimaryHandoffCycleView {
        return PrimaryHandoffCycleView(
            code: item.code,
            labelText: item.label,
            priority: String(item.priority),
            scoreText: String(format: "%.2f", item.score),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryHandoffCycleViews(_ items: [PrimaryHandoffCycle]) -> [PrimaryHandoffCycleView] {
        var views: [PrimaryHandoffCycleView] = []
        for item in items {
            views.append(toPrimaryHandoffCycleView(item))
        }
        return views
    }

    static func sumPrimaryHandoffCycleView(_ view: PrimaryHandoffCycleView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedPriority) + parsedScore
    }
}
