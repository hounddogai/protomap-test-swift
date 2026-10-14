import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStrictClaimAllocationsForVariance(_ items: [StrictClaimAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveLenientAuthorizationVariancesFromAllocation(_ items: [StrictClaimAllocation]) -> [LenientAuthorizationVariance] {
        var out: [LenientAuthorizationVariance] = []
        for item in items {
            let derived = newLenientAuthorizationVariance(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeLenientAuthorizationVariance(_ item: LenientAuthorizationVariance) -> String {
        return classifyStrictClaimAllocation(item.effectiveVolume())
    }
}
