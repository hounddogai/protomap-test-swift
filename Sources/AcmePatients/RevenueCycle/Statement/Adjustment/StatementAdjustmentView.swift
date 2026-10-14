import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement adjustment.
    final class StatementAdjustmentView {
        var codeText: String
        var label: String
        var ceiling: String
        var categoryText: String
        var encounterID: String
        var priority: String
        var dosageMg: String
        var visitMinutes: String
        var channelText: String
        var statusLabel: String

        init(codeText: String, label: String, ceiling: String, categoryText: String, encounterID: String, priority: String, dosageMg: String, visitMinutes: String, channelText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ceiling = ceiling
            self.categoryText = categoryText
            self.encounterID = encounterID
            self.priority = priority
            self.dosageMg = dosageMg
            self.visitMinutes = visitMinutes
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toStatementAdjustmentView(_ item: StatementAdjustment) -> StatementAdjustmentView {
        return StatementAdjustmentView(
            codeText: item.code,
            label: item.label,
            ceiling: String(format: "%.2f", item.ceiling),
            categoryText: item.category,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            priority: String(item.priority),
            dosageMg: String(format: "%.2f", item.dosageMg),
            visitMinutes: String(item.visitMinutes),
            channelText: Kit.Text.truncate(item.channel, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementAdjustmentViews(_ items: [StatementAdjustment]) -> [StatementAdjustmentView] {
        var views: [StatementAdjustmentView] = []
        for item in items {
            views.append(toStatementAdjustmentView(item))
        }
        return views
    }

    static func sumStatementAdjustmentView(_ view: StatementAdjustmentView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedCeiling + Double(parsedPriority) + parsedDosageMg
    }
}
