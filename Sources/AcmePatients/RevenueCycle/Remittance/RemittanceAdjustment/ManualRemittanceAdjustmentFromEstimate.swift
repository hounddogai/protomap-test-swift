import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedClaimEstimatesForAdjustment(_ items: [BatchedClaimEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualRemittanceAdjustmentsFromEstimate(_ items: [BatchedClaimEstimate]) -> [ManualRemittanceAdjustment] {
        var out: [ManualRemittanceAdjustment] = []
        for item in items {
            let derived = newManualRemittanceAdjustment(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchManualRemittanceAdjustment(_ item: ManualRemittanceAdjustment) -> String {
        return classifyBatchedClaimEstimate(item.projectedExposure())
    }
}
