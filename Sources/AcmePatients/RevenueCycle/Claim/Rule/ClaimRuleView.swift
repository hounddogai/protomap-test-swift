import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim rule.
    final class ClaimRuleView {
        var codeText: String
        var title: String
        var locale: String
        var sequence: String
        var source: String
        var active: String
        var startsAt: String
        var currency: String
        var statusLabel: String

        init(codeText: String, title: String, locale: String, sequence: String, source: String, active: String, startsAt: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.locale = locale
            self.sequence = sequence
            self.source = source
            self.active = active
            self.startsAt = startsAt
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toClaimRuleView(_ item: ClaimRule) -> ClaimRuleView {
        return ClaimRuleView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            locale: Kit.Text.truncate(item.locale, limit: 64),
            sequence: String(item.sequence),
            source: item.source,
            active: "\(item.active)",
            startsAt: String(item.startsAt),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimRuleViews(_ items: [ClaimRule]) -> [ClaimRuleView] {
        var views: [ClaimRuleView] = []
        for item in items {
            views.append(toClaimRuleView(item))
        }
        return views
    }

    static func sumClaimRuleView(_ view: ClaimRuleView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedSequence) + Double(parsedStartsAt)
    }
}
