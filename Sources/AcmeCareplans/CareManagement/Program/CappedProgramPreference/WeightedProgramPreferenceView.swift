import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted program preference.
    final class WeightedProgramPreferenceView {
        var code: String
        var label: String
        var ratio: String
        var categoryText: String
        var rate: String
        var statusLabel: String

        init(code: String, label: String, ratio: String, categoryText: String, rate: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.categoryText = categoryText
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedProgramPreferenceView(_ item: WeightedProgramPreference) -> WeightedProgramPreferenceView {
        return WeightedProgramPreferenceView(
            code: item.code,
            label: item.label,
            ratio: String(format: "%.2f", item.ratio),
            categoryText: item.category,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedProgramPreferenceViews(_ items: [WeightedProgramPreference]) -> [WeightedProgramPreferenceView] {
        var views: [WeightedProgramPreferenceView] = []
        for item in items {
            views.append(toWeightedProgramPreferenceView(item))
        }
        return views
    }

    static func sumWeightedProgramPreferenceView(_ view: WeightedProgramPreferenceView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedRatio + parsedRate
    }
}
