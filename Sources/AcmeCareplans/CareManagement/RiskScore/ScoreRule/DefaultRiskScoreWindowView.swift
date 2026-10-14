import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a default risk score window.
    final class DefaultRiskScoreWindowView {
        var code: String
        var titleText: String
        var durationMinutes: String
        var cost: String
        var threshold: String
        var weight: String
        var statusLabel: String

        init(code: String, titleText: String, durationMinutes: String, cost: String, threshold: String, weight: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.durationMinutes = durationMinutes
            self.cost = cost
            self.threshold = threshold
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultRiskScoreWindowView(_ item: DefaultRiskScoreWindow) -> DefaultRiskScoreWindowView {
        return DefaultRiskScoreWindowView(
            code: item.code,
            titleText: item.title,
            durationMinutes: String(item.durationMinutes),
            cost: String(format: "%.2f", item.cost),
            threshold: String(format: "%.2f", item.threshold),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultRiskScoreWindowViews(_ items: [DefaultRiskScoreWindow]) -> [DefaultRiskScoreWindowView] {
        var views: [DefaultRiskScoreWindowView] = []
        for item in items {
            views.append(toDefaultRiskScoreWindowView(item))
        }
        return views
    }

    static func sumDefaultRiskScoreWindowView(_ view: DefaultRiskScoreWindowView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedDurationMinutes) + parsedCost + parsedThreshold
    }
}
