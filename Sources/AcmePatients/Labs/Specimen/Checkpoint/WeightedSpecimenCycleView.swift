import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted specimen cycle.
    final class WeightedSpecimenCycleView {
        var code: String
        var name: String
        var ward: String
        var updatedAtText: String
        var threshold: String
        var rate: String
        var minimumText: String
        var retriesText: String
        var maximum: String
        var statusLabel: String

        init(code: String, name: String, ward: String, updatedAtText: String, threshold: String, rate: String, minimumText: String, retriesText: String, maximum: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ward = ward
            self.updatedAtText = updatedAtText
            self.threshold = threshold
            self.rate = rate
            self.minimumText = minimumText
            self.retriesText = retriesText
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSpecimenCycleView(_ item: WeightedSpecimenCycle) -> WeightedSpecimenCycleView {
        return WeightedSpecimenCycleView(
            code: item.code,
            name: item.name,
            ward: item.ward,
            updatedAtText: String(item.updatedAt),
            threshold: String(format: "%.2f", item.threshold),
            rate: String(format: "%.2f", item.rate),
            minimumText: String(format: "%.2f", item.minimum),
            retriesText: String(item.retries),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSpecimenCycleViews(_ items: [WeightedSpecimenCycle]) -> [WeightedSpecimenCycleView] {
        var views: [WeightedSpecimenCycleView] = []
        for item in items {
            views.append(toWeightedSpecimenCycleView(item))
        }
        return views
    }

    static func sumWeightedSpecimenCycleView(_ view: WeightedSpecimenCycleView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedUpdatedAt) + parsedThreshold + parsedRate
    }
}
