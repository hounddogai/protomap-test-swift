import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback outreach rule.
    final class FallbackOutreachRuleView {
        var code: String
        var labelText: String
        var archived: String
        var expiresAtText: String
        var amount: String
        var rate: String
        var approved: String
        var endsAtText: String
        var limit: String
        var countryText: String
        var statusLabel: String

        init(code: String, labelText: String, archived: String, expiresAtText: String, amount: String, rate: String, approved: String, endsAtText: String, limit: String, countryText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.archived = archived
            self.expiresAtText = expiresAtText
            self.amount = amount
            self.rate = rate
            self.approved = approved
            self.endsAtText = endsAtText
            self.limit = limit
            self.countryText = countryText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackOutreachRuleView(_ item: FallbackOutreachRule) -> FallbackOutreachRuleView {
        return FallbackOutreachRuleView(
            code: item.code,
            labelText: item.label,
            archived: "\(item.archived)",
            expiresAtText: String(item.expiresAt),
            amount: String(format: "%.2f", item.amount),
            rate: String(format: "%.2f", item.rate),
            approved: "\(item.approved)",
            endsAtText: String(item.endsAt),
            limit: String(item.limit),
            countryText: Kit.Text.truncate(item.country, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackOutreachRuleViews(_ items: [FallbackOutreachRule]) -> [FallbackOutreachRuleView] {
        var views: [FallbackOutreachRuleView] = []
        for item in items {
            views.append(toFallbackOutreachRuleView(item))
        }
        return views
    }

    static func sumFallbackOutreachRuleView(_ view: FallbackOutreachRuleView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedExpiresAt) + parsedAmount + parsedRate
    }
}
