import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a weighted rounding preference.
    final class WeightedRoundingPreferenceView {
        var code: String
        var label: String
        var ceiling: String
        var rate: String
        var procedureCode: String
        var attempts: String
        var region: String
        var statusLabel: String

        init(code: String, label: String, ceiling: String, rate: String, procedureCode: String, attempts: String, region: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.rate = rate
            self.procedureCode = procedureCode
            self.attempts = attempts
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedRoundingPreferenceView(_ item: WeightedRoundingPreference) -> WeightedRoundingPreferenceView {
        return WeightedRoundingPreferenceView(
            code: item.code,
            label: item.label,
            ceiling: String(format: "%.2f", item.ceiling),
            rate: String(format: "%.2f", item.rate),
            procedureCode: item.procedureCode,
            attempts: String(item.attempts),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedRoundingPreferenceViews(_ items: [WeightedRoundingPreference]) -> [WeightedRoundingPreferenceView] {
        var views: [WeightedRoundingPreferenceView] = []
        for item in items {
            views.append(toWeightedRoundingPreferenceView(item))
        }
        return views
    }

    static func sumWeightedRoundingPreferenceView(_ view: WeightedRoundingPreferenceView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedCeiling + parsedRate + Double(parsedAttempts)
    }
}
