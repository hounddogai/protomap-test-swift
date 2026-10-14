import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal target.
    final class GoalTargetView {
        var code: String
        var nameText: String
        var capacityText: String
        var unit: String
        var attempts: String
        var categoryText: String
        var source: String
        var durationMinutesText: String
        var dosageMgText: String
        var createdAtText: String
        var statusLabel: String

        init(code: String, nameText: String, capacityText: String, unit: String, attempts: String, categoryText: String, source: String, durationMinutesText: String, dosageMgText: String, createdAtText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.capacityText = capacityText
            self.unit = unit
            self.attempts = attempts
            self.categoryText = categoryText
            self.source = source
            self.durationMinutesText = durationMinutesText
            self.dosageMgText = dosageMgText
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toGoalTargetView(_ item: GoalTarget) -> GoalTargetView {
        return GoalTargetView(
            code: item.code,
            nameText: item.name,
            capacityText: String(item.capacity),
            unit: Kit.Text.truncate(item.unit, limit: 120),
            attempts: String(item.attempts),
            categoryText: item.category,
            source: item.source,
            durationMinutesText: String(item.durationMinutes),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalTargetViews(_ items: [GoalTarget]) -> [GoalTargetView] {
        var views: [GoalTargetView] = []
        for item in items {
            views.append(toGoalTargetView(item))
        }
        return views
    }

    static func sumGoalTargetView(_ view: GoalTargetView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedCapacity) + Double(parsedAttempts) + Double(parsedDurationMinutes)
    }
}
