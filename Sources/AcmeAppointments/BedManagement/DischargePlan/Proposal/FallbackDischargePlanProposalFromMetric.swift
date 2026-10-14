import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeWeightedDischargePlanMetricsForProposal(_ items: [WeightedDischargePlanMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveFallbackDischargePlanProposalsFromMetric(_ items: [WeightedDischargePlanMetric]) -> [FallbackDischargePlanProposal] {
        var out: [FallbackDischargePlanProposal] = []
        for item in items {
            let derived = newFallbackDischargePlanProposal(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveFallbackDischargePlanProposal(_ item: FallbackDischargePlanProposal) -> String {
        return dischargePlanLedgerBucket(item.measuredValue())
    }
}
