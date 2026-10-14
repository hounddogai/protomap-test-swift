import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a seasonal remittance assignment.
    final class SeasonalRemittanceAssignmentView {
        var code: String
        var label: String
        var segment: String
        var budget: String
        var statusLabel: String

        init(code: String, label: String, segment: String, budget: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.segment = segment
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalRemittanceAssignmentView(_ item: SeasonalRemittanceAssignment) -> SeasonalRemittanceAssignmentView {
        return SeasonalRemittanceAssignmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            segment: item.segment,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalRemittanceAssignmentViews(_ items: [SeasonalRemittanceAssignment]) -> [SeasonalRemittanceAssignmentView] {
        var views: [SeasonalRemittanceAssignmentView] = []
        for item in items {
            views.append(toSeasonalRemittanceAssignmentView(item))
        }
        return views
    }

    static func sumSeasonalRemittanceAssignmentView(_ view: SeasonalRemittanceAssignmentView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedBudget
    }
}
