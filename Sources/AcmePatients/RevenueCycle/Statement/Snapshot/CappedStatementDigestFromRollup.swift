import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAdaptiveClaimRollupsForDigest(_ items: [AdaptiveClaimRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveCappedStatementDigestsFromRollup(_ items: [AdaptiveClaimRollup]) -> [CappedStatementDigest] {
        var out: [CappedStatementDigest] = []
        for item in items {
            let derived = newCappedStatementDigest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignCappedStatementDigest(_ item: CappedStatementDigest) -> String {
        return adaptiveClaimRollupBucket(item.measuredValue())
    }
}
