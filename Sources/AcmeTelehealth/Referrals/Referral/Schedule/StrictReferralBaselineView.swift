import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict referral baseline.
    final class StrictReferralBaselineView {
        var code: String
        var nameText: String
        var attempts: String
        var externalRefText: String
        var currencyText: String
        var capacity: String
        var refillsText: String
        var source: String
        var timezone: String
        var statusLabel: String

        init(code: String, nameText: String, attempts: String, externalRefText: String, currencyText: String, capacity: String, refillsText: String, source: String, timezone: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.attempts = attempts
            self.externalRefText = externalRefText
            self.currencyText = currencyText
            self.capacity = capacity
            self.refillsText = refillsText
            self.source = source
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toStrictReferralBaselineView(_ item: StrictReferralBaseline) -> StrictReferralBaselineView {
        return StrictReferralBaselineView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: Kit.Text.truncate(item.name, limit: 64),
            attempts: String(item.attempts),
            externalRefText: item.externalRef,
            currencyText: Kit.Text.truncate(item.currency, limit: 64),
            capacity: String(item.capacity),
            refillsText: String(item.refills),
            source: Kit.Text.truncate(item.source, limit: 120),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictReferralBaselineViews(_ items: [StrictReferralBaseline]) -> [StrictReferralBaselineView] {
        var views: [StrictReferralBaselineView] = []
        for item in items {
            views.append(toStrictReferralBaselineView(item))
        }
        return views
    }

    static func sumStrictReferralBaselineView(_ view: StrictReferralBaselineView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedAttempts) + Double(parsedCapacity) + Double(parsedRefills)
    }
}
