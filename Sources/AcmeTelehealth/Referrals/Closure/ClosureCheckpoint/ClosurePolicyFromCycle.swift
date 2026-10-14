import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeAdaptiveNetworkCyclesForPolicy(_ items: [AdaptiveNetworkCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveClosurePoliciesFromCycle(_ items: [AdaptiveNetworkCycle]) -> [ClosurePolicy] {
        var out: [ClosurePolicy] = []
        for item in items {
            let derived = newClosurePolicy(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceClosurePolicy(_ item: ClosurePolicy) -> String {
        return normalizeRegionalNetworkScoreCode(item.code)
    }
}
