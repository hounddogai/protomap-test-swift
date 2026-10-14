import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive dispense rule.
    final class AdaptiveDispenseRuleView {
        var code: String
        var title: String
        var notesText: String
        var amountText: String
        var patientRef: String
        var category: String
        var ratio: String
        var copay: String
        var payerText: String
        var timezone: String
        var statusLabel: String

        init(code: String, title: String, notesText: String, amountText: String, patientRef: String, category: String, ratio: String, copay: String, payerText: String, timezone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.notesText = notesText
            self.amountText = amountText
            self.patientRef = patientRef
            self.category = category
            self.ratio = ratio
            self.copay = copay
            self.payerText = payerText
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveDispenseRuleView(_ item: AdaptiveDispenseRule) -> AdaptiveDispenseRuleView {
        return AdaptiveDispenseRuleView(
            code: item.code,
            title: item.title,
            notesText: item.notes,
            amountText: String(format: "%.2f", item.amount),
            patientRef: item.patientRef,
            category: item.category,
            ratio: String(format: "%.2f", item.ratio),
            copay: String(format: "%.2f", item.copay),
            payerText: item.payer,
            timezone: Kit.Text.truncate(item.timezone, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveDispenseRuleViews(_ items: [AdaptiveDispenseRule]) -> [AdaptiveDispenseRuleView] {
        var views: [AdaptiveDispenseRuleView] = []
        for item in items {
            views.append(toAdaptiveDispenseRuleView(item))
        }
        return views
    }

    static func sumAdaptiveDispenseRuleView(_ view: AdaptiveDispenseRuleView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedAmount + parsedRatio + parsedCopay
    }
}
