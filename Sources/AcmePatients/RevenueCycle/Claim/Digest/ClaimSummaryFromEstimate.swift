import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRollingClaimEstimatesForSummary(_ items: [RollingClaimEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveClaimSummariesFromEstimate(_ items: [RollingClaimEstimate]) -> [ClaimSummary] {
        var out: [ClaimSummary] = []
        for item in items {
            let derived = newClaimSummary(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeClaimSummary(_ item: ClaimSummary) -> String {
        return claimAdjustmentBucket(item.weightedValue())
    }
}
