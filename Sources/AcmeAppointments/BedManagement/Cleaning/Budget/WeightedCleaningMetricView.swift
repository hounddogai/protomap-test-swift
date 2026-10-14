import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a weighted cleaning metric.
    final class WeightedCleaningMetricView {
        var code: String
        var name: String
        var category: String
        var capacity: String
        var encounterID: String
        var ward: String
        var procedureCode: String
        var ratio: String
        var statusLabel: String

        init(code: String, name: String, category: String, capacity: String, encounterID: String, ward: String, procedureCode: String, ratio: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.category = category
            self.capacity = capacity
            self.encounterID = encounterID
            self.ward = ward
            self.procedureCode = procedureCode
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCleaningMetricView(_ item: WeightedCleaningMetric) -> WeightedCleaningMetricView {
        return WeightedCleaningMetricView(
            code: item.code,
            name: item.name,
            category: item.category,
            capacity: String(item.capacity),
            encounterID: item.encounterID,
            ward: item.ward,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCleaningMetricViews(_ items: [WeightedCleaningMetric]) -> [WeightedCleaningMetricView] {
        var views: [WeightedCleaningMetricView] = []
        for item in items {
            views.append(toWeightedCleaningMetricView(item))
        }
        return views
    }

    static func sumWeightedCleaningMetricView(_ view: WeightedCleaningMetricView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedCapacity) + parsedRatio
    }
}
