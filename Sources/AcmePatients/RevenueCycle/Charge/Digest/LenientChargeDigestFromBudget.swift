import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceBudgetsForDigest(_ items: [RemittanceBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveLenientChargeDigestsFromBudget(_ items: [RemittanceBudget]) -> [LenientChargeDigest] {
        var out: [LenientChargeDigest] = []
        for item in items {
            let derived = newLenientChargeDigest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveLenientChargeDigest(_ item: LenientChargeDigest) -> String {
        return tieredRemittanceAllocationBucket(item.measuredValue())
    }
}
