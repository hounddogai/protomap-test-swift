import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a primary program budget.
    final class PrimaryProgramBudgetView {
        var code: String
        var labelText: String
        var payerText: String
        var ceiling: String
        var windowDaysText: String
        var statusLabel: String

        init(code: String, labelText: String, payerText: String, ceiling: String, windowDaysText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.payerText = payerText
            self.ceiling = ceiling
            self.windowDaysText = windowDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryProgramBudgetView(_ item: PrimaryProgramBudget) -> PrimaryProgramBudgetView {
        return PrimaryProgramBudgetView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            payerText: Kit.Text.truncate(item.payer, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            windowDaysText: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryProgramBudgetViews(_ items: [PrimaryProgramBudget]) -> [PrimaryProgramBudgetView] {
        var views: [PrimaryProgramBudgetView] = []
        for item in items {
            views.append(toPrimaryProgramBudgetView(item))
        }
        return views
    }

    static func sumPrimaryProgramBudgetView(_ view: PrimaryProgramBudgetView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedCeiling + Double(parsedWindowDays)
    }
}
