import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral target.
    final class ReferralTargetView {
        var codeText: String
        var name: String
        var maximum: String
        var minimumText: String
        var expiresAtText: String
        var statusLabel: String

        init(codeText: String, name: String, maximum: String, minimumText: String, expiresAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.maximum = maximum
            self.minimumText = minimumText
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toReferralTargetView(_ item: ReferralTarget) -> ReferralTargetView {
        return ReferralTargetView(
            codeText: item.code,
            name: item.name,
            maximum: String(format: "%.2f", item.maximum),
            minimumText: String(format: "%.2f", item.minimum),
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralTargetViews(_ items: [ReferralTarget]) -> [ReferralTargetView] {
        var views: [ReferralTargetView] = []
        for item in items {
            views.append(toReferralTargetView(item))
        }
        return views
    }

    static func sumReferralTargetView(_ view: ReferralTargetView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedMaximum + parsedMinimum + Double(parsedExpiresAt)
    }
}
