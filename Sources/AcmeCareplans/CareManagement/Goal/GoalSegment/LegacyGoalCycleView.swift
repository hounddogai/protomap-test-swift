import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy goal cycle.
    final class LegacyGoalCycleView {
        var codeText: String
        var title: String
        var wardText: String
        var floorValue: String
        var scoreText: String
        var active: String
        var startsAt: String
        var statusLabel: String

        init(codeText: String, title: String, wardText: String, floorValue: String, scoreText: String, active: String, startsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.wardText = wardText
            self.floorValue = floorValue
            self.scoreText = scoreText
            self.active = active
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyGoalCycleView(_ item: LegacyGoalCycle) -> LegacyGoalCycleView {
        return LegacyGoalCycleView(
            codeText: item.code,
            title: item.title,
            wardText: item.ward,
            floorValue: String(format: "%.2f", item.floorValue),
            scoreText: String(format: "%.2f", item.score),
            active: "\(item.active)",
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyGoalCycleViews(_ items: [LegacyGoalCycle]) -> [LegacyGoalCycleView] {
        var views: [LegacyGoalCycleView] = []
        for item in items {
            views.append(toLegacyGoalCycleView(item))
        }
        return views
    }

    static func sumLegacyGoalCycleView(_ view: LegacyGoalCycleView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedFloorValue + parsedScore + Double(parsedStartsAt)
    }
}
