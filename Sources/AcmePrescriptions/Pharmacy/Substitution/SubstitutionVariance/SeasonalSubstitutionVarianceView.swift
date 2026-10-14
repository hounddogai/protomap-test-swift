import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a seasonal substitution variance.
    final class SeasonalSubstitutionVarianceView {
        var code: String
        var name: String
        var diagnosisCode: String
        var cost: String
        var capacity: String
        var margin: String
        var budget: String
        var statusLabel: String

        init(code: String, name: String, diagnosisCode: String, cost: String, capacity: String, margin: String, budget: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.diagnosisCode = diagnosisCode
            self.cost = cost
            self.capacity = capacity
            self.margin = margin
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalSubstitutionVarianceView(_ item: SeasonalSubstitutionVariance) -> SeasonalSubstitutionVarianceView {
        return SeasonalSubstitutionVarianceView(
            code: item.code,
            name: item.name,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            cost: String(format: "%.2f", item.cost),
            capacity: String(item.capacity),
            margin: String(format: "%.2f", item.margin),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalSubstitutionVarianceViews(_ items: [SeasonalSubstitutionVariance]) -> [SeasonalSubstitutionVarianceView] {
        var views: [SeasonalSubstitutionVarianceView] = []
        for item in items {
            views.append(toSeasonalSubstitutionVarianceView(item))
        }
        return views
    }

    static func sumSeasonalSubstitutionVarianceView(_ view: SeasonalSubstitutionVarianceView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedCost + Double(parsedCapacity) + parsedMargin
    }
}
