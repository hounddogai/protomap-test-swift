import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility policy.
    final class EligibilityPolicyView {
        var codeText: String
        var nameText: String
        var expiresAtText: String
        var threshold: String
        var ownerIDText: String
        var updatedAtText: String
        var statusLabel: String

        init(codeText: String, nameText: String, expiresAtText: String, threshold: String, ownerIDText: String, updatedAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.expiresAtText = expiresAtText
            self.threshold = threshold
            self.ownerIDText = ownerIDText
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityPolicyView(_ item: EligibilityPolicy) -> EligibilityPolicyView {
        return EligibilityPolicyView(
            codeText: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 40),
            expiresAtText: String(item.expiresAt),
            threshold: String(format: "%.2f", item.threshold),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 64),
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityPolicyViews(_ items: [EligibilityPolicy]) -> [EligibilityPolicyView] {
        var views: [EligibilityPolicyView] = []
        for item in items {
            views.append(toEligibilityPolicyView(item))
        }
        return views
    }

    static func sumEligibilityPolicyView(_ view: EligibilityPolicyView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedExpiresAt) + parsedThreshold + Double(parsedUpdatedAt)
    }
}
