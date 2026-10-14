import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a legacy referral claim.
    final class LegacyReferralClaimView {
        var code: String
        var name: String
        var quantity: String
        var updatedAt: String
        var unitText: String
        var refillsText: String
        var bed: String
        var statusLabel: String

        init(code: String, name: String, quantity: String, updatedAt: String, unitText: String, refillsText: String, bed: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.updatedAt = updatedAt
            self.unitText = unitText
            self.refillsText = refillsText
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyReferralClaimView(_ item: LegacyReferralClaim) -> LegacyReferralClaimView {
        return LegacyReferralClaimView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            quantity: String(item.quantity),
            updatedAt: String(item.updatedAt),
            unitText: item.unit,
            refillsText: String(item.refills),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyReferralClaimViews(_ items: [LegacyReferralClaim]) -> [LegacyReferralClaimView] {
        var views: [LegacyReferralClaimView] = []
        for item in items {
            views.append(toLegacyReferralClaimView(item))
        }
        return views
    }

    static func sumLegacyReferralClaimView(_ view: LegacyReferralClaimView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedQuantity) + Double(parsedUpdatedAt) + Double(parsedRefills)
    }
}
