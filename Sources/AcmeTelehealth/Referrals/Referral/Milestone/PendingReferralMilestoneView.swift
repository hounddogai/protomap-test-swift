import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a pending referral milestone.
    final class PendingReferralMilestoneView {
        var code: String
        var name: String
        var unitText: String
        var expiresAt: String
        var payer: String
        var minimum: String
        var createdAtText: String
        var contactEmail: String
        var allergy: String
        var statusLabel: String

        init(code: String, name: String, unitText: String, expiresAt: String, payer: String, minimum: String, createdAtText: String, contactEmail: String, allergy: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.unitText = unitText
            self.expiresAt = expiresAt
            self.payer = payer
            self.minimum = minimum
            self.createdAtText = createdAtText
            self.contactEmail = contactEmail
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReferralMilestoneView(_ item: PendingReferralMilestone) -> PendingReferralMilestoneView {
        return PendingReferralMilestoneView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            unitText: item.unit,
            expiresAt: String(item.expiresAt),
            payer: item.payer,
            minimum: String(format: "%.2f", item.minimum),
            createdAtText: String(item.createdAt),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReferralMilestoneViews(_ items: [PendingReferralMilestone]) -> [PendingReferralMilestoneView] {
        var views: [PendingReferralMilestoneView] = []
        for item in items {
            views.append(toPendingReferralMilestoneView(item))
        }
        return views
    }

    static func sumPendingReferralMilestoneView(_ view: PendingReferralMilestoneView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedExpiresAt) + parsedMinimum + Double(parsedCreatedAt)
    }
}
