import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral manifest.
    final class ReferralManifestView {
        var code: String
        var name: String
        var capacity: String
        var payer: String
        var summary: String
        var statusLabel: String

        init(code: String, name: String, capacity: String, payer: String, summary: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.payer = payer
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toReferralManifestView(_ item: ReferralManifest) -> ReferralManifestView {
        return ReferralManifestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            capacity: String(item.capacity),
            payer: item.payer,
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralManifestViews(_ items: [ReferralManifest]) -> [ReferralManifestView] {
        var views: [ReferralManifestView] = []
        for item in items {
            views.append(toReferralManifestView(item))
        }
        return views
    }

    static func sumReferralManifestView(_ view: ReferralManifestView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedCapacity)
    }
}
