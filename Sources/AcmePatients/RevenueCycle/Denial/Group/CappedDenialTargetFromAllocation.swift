import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimAllocationsForTarget(_ items: [ClaimAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCappedDenialTargetsFromAllocation(_ items: [ClaimAllocation]) -> [CappedDenialTarget] {
        var out: [CappedDenialTarget] = []
        for item in items {
            let derived = newCappedDenialTarget(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyCappedDenialTarget(_ item: CappedDenialTarget) -> String {
        return normalizeClaimAllocationCode(item.code)
    }
}
