import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal priority metric.
    final class SeasonalPriorityMetricView {
        var codeText: String
        var label: String
        var bed: String
        var limitText: String
        var ward: String
        var rate: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, label: String, bed: String, limitText: String, ward: String, rate: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.bed = bed
            self.limitText = limitText
            self.ward = ward
            self.rate = rate
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalPriorityMetricView(_ item: SeasonalPriorityMetric) -> SeasonalPriorityMetricView {
        return SeasonalPriorityMetricView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            bed: item.bed,
            limitText: String(item.limit),
            ward: item.ward,
            rate: String(format: "%.2f", item.rate),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalPriorityMetricViews(_ items: [SeasonalPriorityMetric]) -> [SeasonalPriorityMetricView] {
        var views: [SeasonalPriorityMetricView] = []
        for item in items {
            views.append(toSeasonalPriorityMetricView(item))
        }
        return views
    }

    static func sumSeasonalPriorityMetricView(_ view: SeasonalPriorityMetricView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedLimit) + parsedRate + parsedFloorValue
    }
}
