import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped closure rule.
    final class CappedClosureRuleView {
        var code: String
        var label: String
        var encounterID: String
        var sourceText: String
        var timezone: String
        var copay: String
        var currency: String
        var activeText: String
        var statusLabel: String

        init(code: String, label: String, encounterID: String, sourceText: String, timezone: String, copay: String, currency: String, activeText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.sourceText = sourceText
            self.timezone = timezone
            self.copay = copay
            self.currency = currency
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedClosureRuleView(_ item: CappedClosureRule) -> CappedClosureRuleView {
        return CappedClosureRuleView(
            code: item.code,
            label: item.label,
            encounterID: item.encounterID,
            sourceText: item.source,
            timezone: item.timezone,
            copay: String(format: "%.2f", item.copay),
            currency: item.currency,
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedClosureRuleViews(_ items: [CappedClosureRule]) -> [CappedClosureRuleView] {
        var views: [CappedClosureRuleView] = []
        for item in items {
            views.append(toCappedClosureRuleView(item))
        }
        return views
    }

    static func sumCappedClosureRuleView(_ view: CappedClosureRuleView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedCopay
    }
}
