import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment target.
    final class AssessmentTargetView {
        var code: String
        var label: String
        var rateText: String
        var active: String
        var budget: String
        var statusLabel: String

        init(code: String, label: String, rateText: String, active: String, budget: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.rateText = rateText
            self.active = active
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentTargetView(_ item: AssessmentTarget) -> AssessmentTargetView {
        return AssessmentTargetView(
            code: item.code,
            label: item.label,
            rateText: String(format: "%.2f", item.rate),
            active: "\(item.active)",
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentTargetViews(_ items: [AssessmentTarget]) -> [AssessmentTargetView] {
        var views: [AssessmentTargetView] = []
        for item in items {
            views.append(toAssessmentTargetView(item))
        }
        return views
    }

    static func sumAssessmentTargetView(_ view: AssessmentTargetView) throws -> Double {
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedRate + parsedBudget
    }
}
