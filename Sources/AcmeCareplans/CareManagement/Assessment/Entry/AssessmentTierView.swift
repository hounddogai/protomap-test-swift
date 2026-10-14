import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment tier.
    final class AssessmentTierView {
        var code: String
        var name: String
        var bed: String
        var locale: String
        var budget: String
        var statusLabel: String

        init(code: String, name: String, bed: String, locale: String, budget: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.bed = bed
            self.locale = locale
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentTierView(_ item: AssessmentTier) -> AssessmentTierView {
        return AssessmentTierView(
            code: item.code,
            name: item.name,
            bed: item.bed,
            locale: item.locale,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentTierViews(_ items: [AssessmentTier]) -> [AssessmentTierView] {
        var views: [AssessmentTierView] = []
        for item in items {
            views.append(toAssessmentTierView(item))
        }
        return views
    }

    static func sumAssessmentTierView(_ view: AssessmentTierView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedBudget
    }
}
