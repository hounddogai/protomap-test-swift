import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback skill mix template.
    final class FallbackSkillMixTemplateView {
        var codeText: String
        var label: String
        var score: String
        var discountText: String
        var versionText: String
        var timezone: String
        var refillsText: String
        var amount: String
        var region: String
        var graceDaysText: String
        var budgetText: String
        var statusLabel: String

        init(codeText: String, label: String, score: String, discountText: String, versionText: String, timezone: String, refillsText: String, amount: String, region: String, graceDaysText: String, budgetText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.score = score
            self.discountText = discountText
            self.versionText = versionText
            self.timezone = timezone
            self.refillsText = refillsText
            self.amount = amount
            self.region = region
            self.graceDaysText = graceDaysText
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackSkillMixTemplateView(_ item: FallbackSkillMixTemplate) -> FallbackSkillMixTemplateView {
        return FallbackSkillMixTemplateView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            score: String(format: "%.2f", item.score),
            discountText: String(format: "%.2f", item.discount),
            versionText: String(item.version),
            timezone: item.timezone,
            refillsText: String(item.refills),
            amount: String(format: "%.2f", item.amount),
            region: Kit.Text.truncate(item.region, limit: 40),
            graceDaysText: String(item.graceDays),
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackSkillMixTemplateViews(_ items: [FallbackSkillMixTemplate]) -> [FallbackSkillMixTemplateView] {
        var views: [FallbackSkillMixTemplateView] = []
        for item in items {
            views.append(toFallbackSkillMixTemplateView(item))
        }
        return views
    }

    static func sumFallbackSkillMixTemplateView(_ view: FallbackSkillMixTemplateView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedScore + parsedDiscount + Double(parsedVersion)
    }
}
