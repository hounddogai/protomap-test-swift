import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimaryNetworkBundlesForQuota(_ items: [PrimaryNetworkBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveFollowUpQuotasFromBundle(_ items: [PrimaryNetworkBundle]) -> [FollowUpQuota] {
        var out: [FollowUpQuota] = []
        for item in items {
            let derived = newFollowUpQuota(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateFollowUpQuota(_ item: FollowUpQuota) -> Double {
        return primaryNetworkBundleWeight(9, active: true)
    }
}
