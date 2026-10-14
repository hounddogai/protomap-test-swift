import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal eligibility quota.
    final class SeasonalEligibilityQuotaView {
        var codeText: String
        var name: String
        var phone: String
        var updatedAt: String
        var createdAt: String
        var allergyText: String
        var contactEmailText: String
        var acuityText: String
        var score: String
        var reviewer: String
        var threshold: String
        var statusLabel: String

        init(codeText: String, name: String, phone: String, updatedAt: String, createdAt: String, allergyText: String, contactEmailText: String, acuityText: String, score: String, reviewer: String, threshold: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.phone = phone
            self.updatedAt = updatedAt
            self.createdAt = createdAt
            self.allergyText = allergyText
            self.contactEmailText = contactEmailText
            self.acuityText = acuityText
            self.score = score
            self.reviewer = reviewer
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalEligibilityQuotaView(_ item: SeasonalEligibilityQuota) -> SeasonalEligibilityQuotaView {
        return SeasonalEligibilityQuotaView(
            codeText: item.code,
            name: item.name,
            phone: item.phone,
            updatedAt: String(item.updatedAt),
            createdAt: String(item.createdAt),
            allergyText: item.allergy,
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 40),
            acuityText: String(item.acuity),
            score: String(format: "%.2f", item.score),
            reviewer: item.reviewer,
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalEligibilityQuotaViews(_ items: [SeasonalEligibilityQuota]) -> [SeasonalEligibilityQuotaView] {
        var views: [SeasonalEligibilityQuotaView] = []
        for item in items {
            views.append(toSeasonalEligibilityQuotaView(item))
        }
        return views
    }

    static func sumSeasonalEligibilityQuotaView(_ view: SeasonalEligibilityQuotaView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedCreatedAt) + Double(parsedAcuity)
    }
}
