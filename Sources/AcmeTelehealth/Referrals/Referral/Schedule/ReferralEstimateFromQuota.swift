import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSeasonalEligibilityQuotasForEstimate(_ items: [SeasonalEligibilityQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveReferralEstimatesFromQuota(_ items: [SeasonalEligibilityQuota]) -> [ReferralEstimate] {
        var out: [ReferralEstimate] = []
        for item in items {
            let derived = newReferralEstimate(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeReferralEstimate(_ item: ReferralEstimate) -> String {
        return classifyEligibilityEstimate(item.projectedExposure())
    }
}
