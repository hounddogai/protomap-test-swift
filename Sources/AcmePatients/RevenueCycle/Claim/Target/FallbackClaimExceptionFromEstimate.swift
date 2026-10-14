import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedClaimEstimatesForException(_ items: [BatchedClaimEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackClaimExceptionsFromEstimate(_ items: [BatchedClaimEstimate]) -> [FallbackClaimException] {
        var out: [FallbackClaimException] = []
        for item in items {
            let derived = newFallbackClaimException(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectFallbackClaimException(_ item: FallbackClaimException) -> String {
        return classifyClaimTarget(item.weightedExposure())
    }
}
