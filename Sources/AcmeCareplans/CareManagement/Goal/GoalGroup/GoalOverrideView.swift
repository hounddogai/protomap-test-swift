import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal override.
    final class GoalOverrideView {
        var code: String
        var nameText: String
        var sequence: String
        var visibleText: String
        var threshold: String
        var weightText: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, nameText: String, sequence: String, visibleText: String, threshold: String, weightText: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.sequence = sequence
            self.visibleText = visibleText
            self.threshold = threshold
            self.weightText = weightText
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toGoalOverrideView(_ item: GoalOverride) -> GoalOverrideView {
        return GoalOverrideView(
            code: item.code,
            nameText: item.name,
            sequence: String(item.sequence),
            visibleText: "\(item.visible)",
            threshold: String(format: "%.2f", item.threshold),
            weightText: String(format: "%.2f", item.weight),
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalOverrideViews(_ items: [GoalOverride]) -> [GoalOverrideView] {
        var views: [GoalOverrideView] = []
        for item in items {
            views.append(toGoalOverrideView(item))
        }
        return views
    }

    static func sumGoalOverrideView(_ view: GoalOverrideView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedSequence) + parsedThreshold + parsedWeight
    }
}
