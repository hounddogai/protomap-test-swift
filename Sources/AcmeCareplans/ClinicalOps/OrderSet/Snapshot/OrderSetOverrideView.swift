import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set override.
    final class OrderSetOverrideView {
        var code: String
        var label: String
        var diagnosisCode: String
        var ceiling: String
        var amount: String
        var maximumText: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCode: String, ceiling: String, amount: String, maximumText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.ceiling = ceiling
            self.amount = amount
            self.maximumText = maximumText
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetOverrideView(_ item: OrderSetOverride) -> OrderSetOverrideView {
        return OrderSetOverrideView(
            code: item.code,
            label: item.label,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            amount: String(format: "%.2f", item.amount),
            maximumText: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetOverrideViews(_ items: [OrderSetOverride]) -> [OrderSetOverrideView] {
        var views: [OrderSetOverrideView] = []
        for item in items {
            views.append(toOrderSetOverrideView(item))
        }
        return views
    }

    static func sumOrderSetOverrideView(_ view: OrderSetOverrideView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCeiling + parsedAmount + parsedMaximum
    }
}
