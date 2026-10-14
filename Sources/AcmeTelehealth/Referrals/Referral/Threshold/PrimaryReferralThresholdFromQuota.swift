import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpQuotasForThreshold(_ items: [FollowUpQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func derivePrimaryReferralThresholdsFromQuota(_ items: [FollowUpQuota]) -> [PrimaryReferralThreshold] {
        var out: [PrimaryReferralThreshold] = []
        for item in items {
            let derived = newPrimaryReferralThreshold(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settlePrimaryReferralThreshold(_ item: PrimaryReferralThreshold) -> String {
        return regionalFollowUpDigestBucket(item.measuredValue())
    }
}
