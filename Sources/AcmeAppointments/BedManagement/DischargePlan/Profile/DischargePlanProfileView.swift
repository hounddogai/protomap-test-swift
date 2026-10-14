import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan profile.
    final class DischargePlanProfileView {
        var code: String
        var title: String
        var attempts: String
        var budget: String
        var labelText: String
        var statusLabel: String

        init(code: String, title: String, attempts: String, budget: String, labelText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.budget = budget
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanProfileView(_ item: DischargePlanProfile) -> DischargePlanProfileView {
        return DischargePlanProfileView(
            code: item.code,
            title: item.title,
            attempts: String(item.attempts),
            budget: String(format: "%.2f", item.budget),
            labelText: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanProfileViews(_ items: [DischargePlanProfile]) -> [DischargePlanProfileView] {
        var views: [DischargePlanProfileView] = []
        for item in items {
            views.append(toDischargePlanProfileView(item))
        }
        return views
    }

    static func sumDischargePlanProfileView(_ view: DischargePlanProfileView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedAttempts) + parsedBudget
    }
}
