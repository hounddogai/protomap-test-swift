import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted dispense metric.
    final class WeightedDispenseMetricView {
        var codeText: String
        var name: String
        var procedureCode: String
        var archived: String
        var limit: String
        var thresholdText: String
        var statusLabel: String

        init(codeText: String, name: String, procedureCode: String, archived: String, limit: String, thresholdText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.procedureCode = procedureCode
            self.archived = archived
            self.limit = limit
            self.thresholdText = thresholdText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedDispenseMetricView(_ item: WeightedDispenseMetric) -> WeightedDispenseMetricView {
        return WeightedDispenseMetricView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            procedureCode: item.procedureCode,
            archived: "\(item.archived)",
            limit: String(item.limit),
            thresholdText: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedDispenseMetricViews(_ items: [WeightedDispenseMetric]) -> [WeightedDispenseMetricView] {
        var views: [WeightedDispenseMetricView] = []
        for item in items {
            views.append(toWeightedDispenseMetricView(item))
        }
        return views
    }

    static func sumWeightedDispenseMetricView(_ view: WeightedDispenseMetricView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedLimit) + parsedThreshold
    }
}
