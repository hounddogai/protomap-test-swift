import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional specimen estimate.
    final class RegionalSpecimenEstimateView {
        var code: String
        var label: String
        var diagnosisCodeText: String
        var attemptsText: String
        var visible: String
        var budget: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCodeText: String, attemptsText: String, visible: String, budget: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCodeText = diagnosisCodeText
            self.attemptsText = attemptsText
            self.visible = visible
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalSpecimenEstimateView(_ item: RegionalSpecimenEstimate) -> RegionalSpecimenEstimateView {
        return RegionalSpecimenEstimateView(
            code: item.code,
            label: item.label,
            diagnosisCodeText: item.diagnosisCode,
            attemptsText: String(item.attempts),
            visible: "\(item.visible)",
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalSpecimenEstimateViews(_ items: [RegionalSpecimenEstimate]) -> [RegionalSpecimenEstimateView] {
        var views: [RegionalSpecimenEstimateView] = []
        for item in items {
            views.append(toRegionalSpecimenEstimateView(item))
        }
        return views
    }

    static func sumRegionalSpecimenEstimateView(_ view: RegionalSpecimenEstimateView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedAttempts) + parsedBudget
    }
}
