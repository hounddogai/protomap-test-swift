import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling goal policy.
    final class RollingGoalPolicyView {
        var code: String
        var label: String
        var score: String
        var activeText: String
        var durationMinutes: String
        var phone: String
        var statusLabel: String

        init(code: String, label: String, score: String, activeText: String, durationMinutes: String, phone: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.score = score
            self.activeText = activeText
            self.durationMinutes = durationMinutes
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toRollingGoalPolicyView(_ item: RollingGoalPolicy) -> RollingGoalPolicyView {
        return RollingGoalPolicyView(
            code: item.code,
            label: item.label,
            score: String(format: "%.2f", item.score),
            activeText: "\(item.active)",
            durationMinutes: String(item.durationMinutes),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingGoalPolicyViews(_ items: [RollingGoalPolicy]) -> [RollingGoalPolicyView] {
        var views: [RollingGoalPolicyView] = []
        for item in items {
            views.append(toRollingGoalPolicyView(item))
        }
        return views
    }

    static func sumRollingGoalPolicyView(_ view: RollingGoalPolicyView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedScore + Double(parsedDurationMinutes)
    }
}
