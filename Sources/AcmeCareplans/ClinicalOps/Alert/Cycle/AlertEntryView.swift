import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert entry.
    final class AlertEntryView {
        var code: String
        var titleText: String
        var copay: String
        var externalRef: String
        var budget: String
        var acuity: String
        var payerText: String
        var graceDays: String
        var statusLabel: String

        init(code: String, titleText: String, copay: String, externalRef: String, budget: String, acuity: String, payerText: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.copay = copay
            self.externalRef = externalRef
            self.budget = budget
            self.acuity = acuity
            self.payerText = payerText
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toAlertEntryView(_ item: AlertEntry) -> AlertEntryView {
        return AlertEntryView(
            code: item.code,
            titleText: item.title,
            copay: String(format: "%.2f", item.copay),
            externalRef: item.externalRef,
            budget: String(format: "%.2f", item.budget),
            acuity: String(item.acuity),
            payerText: item.payer,
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertEntryViews(_ items: [AlertEntry]) -> [AlertEntryView] {
        var views: [AlertEntryView] = []
        for item in items {
            views.append(toAlertEntryView(item))
        }
        return views
    }

    static func sumAlertEntryView(_ view: AlertEntryView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedCopay + parsedBudget + Double(parsedAcuity)
    }
}
