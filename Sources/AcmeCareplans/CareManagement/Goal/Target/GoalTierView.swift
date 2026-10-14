import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal tier.
    final class GoalTierView {
        var codeText: String
        var labelText: String
        var titleText: String
        var discount: String
        var timezoneText: String
        var rate: String
        var capacityText: String
        var score: String
        var version: String
        var statusLabel: String

        init(codeText: String, labelText: String, titleText: String, discount: String, timezoneText: String, rate: String, capacityText: String, score: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.titleText = titleText
            self.discount = discount
            self.timezoneText = timezoneText
            self.rate = rate
            self.capacityText = capacityText
            self.score = score
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toGoalTierView(_ item: GoalTier) -> GoalTierView {
        return GoalTierView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            titleText: item.title,
            discount: String(format: "%.2f", item.discount),
            timezoneText: item.timezone,
            rate: String(format: "%.2f", item.rate),
            capacityText: String(item.capacity),
            score: String(format: "%.2f", item.score),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalTierViews(_ items: [GoalTier]) -> [GoalTierView] {
        var views: [GoalTierView] = []
        for item in items {
            views.append(toGoalTierView(item))
        }
        return views
    }

    static func sumGoalTierView(_ view: GoalTierView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedDiscount + parsedRate + Double(parsedCapacity)
    }
}
