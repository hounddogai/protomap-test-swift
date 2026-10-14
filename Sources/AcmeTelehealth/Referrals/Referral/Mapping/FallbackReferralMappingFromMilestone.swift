import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryReferralMilestonesForMapping(_ items: [PrimaryReferralMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveFallbackReferralMappingsFromMilestone(_ items: [PrimaryReferralMilestone]) -> [FallbackReferralMapping] {
        var out: [FallbackReferralMapping] = []
        for item in items {
            let derived = newFallbackReferralMapping(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateFallbackReferralMapping(_ item: FallbackReferralMapping) -> String {
        return referralVarianceBucket(item.effectiveExposure())
    }
}
