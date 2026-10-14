import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLenientClaimSummariesForEstimate(_ items: [LenientClaimSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveDenialEstimatesFromSummary(_ items: [LenientClaimSummary]) -> [DenialEstimate] {
        var out: [DenialEstimate] = []
        for item in items {
            let derived = newDenialEstimate(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planDenialEstimate(_ item: DenialEstimate) -> String {
        return pendingClaimBudgetBucket(item.measuredValue())
    }
}
