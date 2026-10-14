import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning rule.
    final class CleaningRuleView {
        var code: String
        var name: String
        var phoneText: String
        var localeText: String
        var expiresAtText: String
        var channel: String
        var discount: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, name: String, phoneText: String, localeText: String, expiresAtText: String, channel: String, discount: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.phoneText = phoneText
            self.localeText = localeText
            self.expiresAtText = expiresAtText
            self.channel = channel
            self.discount = discount
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningRuleView(_ item: CleaningRule) -> CleaningRuleView {
        return CleaningRuleView(
            code: item.code,
            name: item.name,
            phoneText: Kit.Text.truncate(item.phone, limit: 80),
            localeText: Kit.Text.truncate(item.locale, limit: 120),
            expiresAtText: String(item.expiresAt),
            channel: item.channel,
            discount: String(format: "%.2f", item.discount),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningRuleViews(_ items: [CleaningRule]) -> [CleaningRuleView] {
        var views: [CleaningRuleView] = []
        for item in items {
            views.append(toCleaningRuleView(item))
        }
        return views
    }

    static func sumCleaningRuleView(_ view: CleaningRuleView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedExpiresAt) + parsedDiscount + Double(parsedVisitMinutes)
    }
}
