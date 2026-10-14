import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a rolling goal cycle.
    final class RollingGoalCycleView {
        var code: String
        var titleText: String
        var allergyText: String
        var externalRefText: String
        var amount: String
        var threshold: String
        var ward: String
        var statusLabel: String

        init(code: String, titleText: String, allergyText: String, externalRefText: String, amount: String, threshold: String, ward: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.allergyText = allergyText
            self.externalRefText = externalRefText
            self.amount = amount
            self.threshold = threshold
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toRollingGoalCycleView(_ item: RollingGoalCycle) -> RollingGoalCycleView {
        return RollingGoalCycleView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            allergyText: item.allergy,
            externalRefText: item.externalRef,
            amount: String(format: "%.2f", item.amount),
            threshold: String(format: "%.2f", item.threshold),
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingGoalCycleViews(_ items: [RollingGoalCycle]) -> [RollingGoalCycleView] {
        var views: [RollingGoalCycleView] = []
        for item in items {
            views.append(toRollingGoalCycleView(item))
        }
        return views
    }

    static func sumRollingGoalCycleView(_ view: RollingGoalCycleView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedAmount + parsedThreshold
    }
}
