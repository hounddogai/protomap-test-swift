import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal checkpoint.
    final class GoalCheckpointView {
        var codeText: String
        var title: String
        var floorValueText: String
        var channel: String
        var specialty: String
        var statusLabel: String

        init(codeText: String, title: String, floorValueText: String, channel: String, specialty: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.floorValueText = floorValueText
            self.channel = channel
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toGoalCheckpointView(_ item: GoalCheckpoint) -> GoalCheckpointView {
        return GoalCheckpointView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 40),
            floorValueText: String(format: "%.2f", item.floorValue),
            channel: item.channel,
            specialty: Kit.Text.truncate(item.specialty, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalCheckpointViews(_ items: [GoalCheckpoint]) -> [GoalCheckpointView] {
        var views: [GoalCheckpointView] = []
        for item in items {
            views.append(toGoalCheckpointView(item))
        }
        return views
    }

    static func sumGoalCheckpointView(_ view: GoalCheckpointView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
