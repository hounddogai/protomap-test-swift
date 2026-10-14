import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeManualRoundingRulesForPlan(_ items: [ManualRoundingRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveCappedOrderSetPlansFromRule(_ items: [ManualRoundingRule]) -> [CappedOrderSetPlan] {
        var out: [CappedOrderSetPlan] = []
        for item in items {
            let derived = newCappedOrderSetPlan(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateCappedOrderSetPlan(_ item: CappedOrderSetPlan) -> Double {
        return roundingBatchWeight(1, active: true)
    }
}
