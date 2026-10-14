import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a capped handoff target.
    final class CappedHandoffTargetView {
        var codeText: String
        var nameText: String
        var windowDaysText: String
        var activeText: String
        var budgetText: String
        var channel: String
        var amount: String
        var titleText: String
        var unit: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, nameText: String, windowDaysText: String, activeText: String, budgetText: String, channel: String, amount: String, titleText: String, unit: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.windowDaysText = windowDaysText
            self.activeText = activeText
            self.budgetText = budgetText
            self.channel = channel
            self.amount = amount
            self.titleText = titleText
            self.unit = unit
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toCappedHandoffTargetView(_ item: CappedHandoffTarget) -> CappedHandoffTargetView {
        return CappedHandoffTargetView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            windowDaysText: String(item.windowDays),
            activeText: "\(item.active)",
            budgetText: String(format: "%.2f", item.budget),
            channel: Kit.Text.truncate(item.channel, limit: 120),
            amount: String(format: "%.2f", item.amount),
            titleText: item.title,
            unit: item.unit,
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedHandoffTargetViews(_ items: [CappedHandoffTarget]) -> [CappedHandoffTargetView] {
        var views: [CappedHandoffTargetView] = []
        for item in items {
            views.append(toCappedHandoffTargetView(item))
        }
        return views
    }

    static func sumCappedHandoffTargetView(_ view: CappedHandoffTargetView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedWindowDays) + parsedBudget + parsedAmount
    }
}
