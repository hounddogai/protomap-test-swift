import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a tiered cleaning rule.
    final class TieredCleaningRuleView {
        var codeText: String
        var nameText: String
        var amountText: String
        var limit: String
        var versionText: String
        var discount: String
        var statusLabel: String

        init(codeText: String, nameText: String, amountText: String, limit: String, versionText: String, discount: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.amountText = amountText
            self.limit = limit
            self.versionText = versionText
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toTieredCleaningRuleView(_ item: TieredCleaningRule) -> TieredCleaningRuleView {
        return TieredCleaningRuleView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            amountText: String(format: "%.2f", item.amount),
            limit: String(item.limit),
            versionText: String(item.version),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredCleaningRuleViews(_ items: [TieredCleaningRule]) -> [TieredCleaningRuleView] {
        var views: [TieredCleaningRuleView] = []
        for item in items {
            views.append(toTieredCleaningRuleView(item))
        }
        return views
    }

    static func sumTieredCleaningRuleView(_ view: TieredCleaningRuleView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedAmount + Double(parsedLimit) + Double(parsedVersion)
    }
}
