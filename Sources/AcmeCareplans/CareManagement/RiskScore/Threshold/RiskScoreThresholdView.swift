import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score threshold.
    final class RiskScoreThresholdView {
        var code: String
        var name: String
        var budget: String
        var capacity: String
        var margin: String
        var windowDays: String
        var quantityText: String
        var durationMinutes: String
        var archived: String
        var statusLabel: String

        init(code: String, name: String, budget: String, capacity: String, margin: String, windowDays: String, quantityText: String, durationMinutes: String, archived: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.budget = budget
            self.capacity = capacity
            self.margin = margin
            self.windowDays = windowDays
            self.quantityText = quantityText
            self.durationMinutes = durationMinutes
            self.archived = archived
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreThresholdView(_ item: RiskScoreThreshold) -> RiskScoreThresholdView {
        return RiskScoreThresholdView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            budget: String(format: "%.2f", item.budget),
            capacity: String(item.capacity),
            margin: String(format: "%.2f", item.margin),
            windowDays: String(item.windowDays),
            quantityText: String(item.quantity),
            durationMinutes: String(item.durationMinutes),
            archived: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreThresholdViews(_ items: [RiskScoreThreshold]) -> [RiskScoreThresholdView] {
        var views: [RiskScoreThresholdView] = []
        for item in items {
            views.append(toRiskScoreThresholdView(item))
        }
        return views
    }

    static func sumRiskScoreThresholdView(_ view: RiskScoreThresholdView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedBudget + Double(parsedCapacity) + parsedMargin
    }
}
