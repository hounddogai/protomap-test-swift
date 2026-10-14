import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a primary eligibility quota.
    final class PrimaryEligibilityQuotaView {
        var code: String
        var label: String
        var diagnosisCode: String
        var createdAt: String
        var retries: String
        var statusLabel: String

        init(code: String, label: String, diagnosisCode: String, createdAt: String, retries: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.createdAt = createdAt
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryEligibilityQuotaView(_ item: PrimaryEligibilityQuota) -> PrimaryEligibilityQuotaView {
        return PrimaryEligibilityQuotaView(
            code: item.code,
            label: item.label,
            diagnosisCode: item.diagnosisCode,
            createdAt: String(item.createdAt),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryEligibilityQuotaViews(_ items: [PrimaryEligibilityQuota]) -> [PrimaryEligibilityQuotaView] {
        var views: [PrimaryEligibilityQuotaView] = []
        for item in items {
            views.append(toPrimaryEligibilityQuotaView(item))
        }
        return views
    }

    static func sumPrimaryEligibilityQuotaView(_ view: PrimaryEligibilityQuotaView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedRetries)
    }
}
