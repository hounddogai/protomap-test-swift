import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional network rule.
    final class RegionalNetworkRuleView {
        var code: String
        var title: String
        var batchSizeText: String
        var amountText: String
        var priorityText: String
        var summary: String
        var patientRef: String
        var version: String
        var procedureCodeText: String
        var checksum: String
        var budgetText: String
        var statusLabel: String

        init(code: String, title: String, batchSizeText: String, amountText: String, priorityText: String, summary: String, patientRef: String, version: String, procedureCodeText: String, checksum: String, budgetText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.batchSizeText = batchSizeText
            self.amountText = amountText
            self.priorityText = priorityText
            self.summary = summary
            self.patientRef = patientRef
            self.version = version
            self.procedureCodeText = procedureCodeText
            self.checksum = checksum
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalNetworkRuleView(_ item: RegionalNetworkRule) -> RegionalNetworkRuleView {
        return RegionalNetworkRuleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            batchSizeText: String(item.batchSize),
            amountText: String(format: "%.2f", item.amount),
            priorityText: String(item.priority),
            summary: item.summary,
            patientRef: item.patientRef,
            version: String(item.version),
            procedureCodeText: item.procedureCode,
            checksum: item.checksum,
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalNetworkRuleViews(_ items: [RegionalNetworkRule]) -> [RegionalNetworkRuleView] {
        var views: [RegionalNetworkRuleView] = []
        for item in items {
            views.append(toRegionalNetworkRuleView(item))
        }
        return views
    }

    static func sumRegionalNetworkRuleView(_ view: RegionalNetworkRuleView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedBatchSize) + parsedAmount + Double(parsedPriority)
    }
}
