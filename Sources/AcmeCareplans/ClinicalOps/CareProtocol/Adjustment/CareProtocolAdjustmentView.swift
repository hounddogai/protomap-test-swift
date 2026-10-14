import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol adjustment.
    final class CareProtocolAdjustmentView {
        var code: String
        var name: String
        var budgetText: String
        var copay: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, name: String, budgetText: String, copay: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.budgetText = budgetText
            self.copay = copay
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolAdjustmentView(_ item: CareProtocolAdjustment) -> CareProtocolAdjustmentView {
        return CareProtocolAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            budgetText: String(format: "%.2f", item.budget),
            copay: String(format: "%.2f", item.copay),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolAdjustmentViews(_ items: [CareProtocolAdjustment]) -> [CareProtocolAdjustmentView] {
        var views: [CareProtocolAdjustmentView] = []
        for item in items {
            views.append(toCareProtocolAdjustmentView(item))
        }
        return views
    }

    static func sumCareProtocolAdjustmentView(_ view: CareProtocolAdjustmentView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedBudget + parsedCopay + parsedCeiling
    }
}
