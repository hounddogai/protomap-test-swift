import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert rollup.
    final class AlertRollupView {
        var code: String
        var titleText: String
        var description: String
        var approved: String
        var source: String
        var amount: String
        var statusLabel: String

        init(code: String, titleText: String, description: String, approved: String, source: String, amount: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.description = description
            self.approved = approved
            self.source = source
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toAlertRollupView(_ item: AlertRollup) -> AlertRollupView {
        return AlertRollupView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            description: item.description,
            approved: "\(item.approved)",
            source: item.source,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertRollupViews(_ items: [AlertRollup]) -> [AlertRollupView] {
        var views: [AlertRollupView] = []
        for item in items {
            views.append(toAlertRollupView(item))
        }
        return views
    }

    static func sumAlertRollupView(_ view: AlertRollupView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
