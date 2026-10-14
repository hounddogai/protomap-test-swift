import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert group.
    final class AlertGroupView {
        var codeText: String
        var label: String
        var payerText: String
        var source: String
        var ceiling: String
        var localeText: String
        var encounterID: String
        var active: String
        var statusLabel: String

        init(codeText: String, label: String, payerText: String, source: String, ceiling: String, localeText: String, encounterID: String, active: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.payerText = payerText
            self.source = source
            self.ceiling = ceiling
            self.localeText = localeText
            self.encounterID = encounterID
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toAlertGroupView(_ item: AlertGroup) -> AlertGroupView {
        return AlertGroupView(
            codeText: item.code,
            label: item.label,
            payerText: Kit.Text.truncate(item.payer, limit: 80),
            source: Kit.Text.truncate(item.source, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            localeText: item.locale,
            encounterID: item.encounterID,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertGroupViews(_ items: [AlertGroup]) -> [AlertGroupView] {
        var views: [AlertGroupView] = []
        for item in items {
            views.append(toAlertGroupView(item))
        }
        return views
    }

    static func sumAlertGroupView(_ view: AlertGroupView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
