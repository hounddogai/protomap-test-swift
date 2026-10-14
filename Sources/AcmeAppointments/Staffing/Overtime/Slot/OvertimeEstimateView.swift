import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime estimate.
    final class OvertimeEstimateView {
        var code: String
        var labelText: String
        var score: String
        var weightText: String
        var graceDaysText: String
        var cost: String
        var maximumText: String
        var locale: String
        var statusLabel: String

        init(code: String, labelText: String, score: String, weightText: String, graceDaysText: String, cost: String, maximumText: String, locale: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.score = score
            self.weightText = weightText
            self.graceDaysText = graceDaysText
            self.cost = cost
            self.maximumText = maximumText
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeEstimateView(_ item: OvertimeEstimate) -> OvertimeEstimateView {
        return OvertimeEstimateView(
            code: item.code,
            labelText: item.label,
            score: String(format: "%.2f", item.score),
            weightText: String(format: "%.2f", item.weight),
            graceDaysText: String(item.graceDays),
            cost: String(format: "%.2f", item.cost),
            maximumText: String(format: "%.2f", item.maximum),
            locale: item.locale,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeEstimateViews(_ items: [OvertimeEstimate]) -> [OvertimeEstimateView] {
        var views: [OvertimeEstimateView] = []
        for item in items {
            views.append(toOvertimeEstimateView(item))
        }
        return views
    }

    static func sumOvertimeEstimateView(_ view: OvertimeEstimateView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedScore + parsedWeight + Double(parsedGraceDays)
    }
}
