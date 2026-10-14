import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeBatchedNetworkCyclesForLedger(_ items: [BatchedNetworkCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveClosureLedgersFromCycle(_ items: [BatchedNetworkCycle]) -> [ClosureLedger] {
        var out: [ClosureLedger] = []
        for item in items {
            let derived = newClosureLedger(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeClosureLedger(_ item: ClosureLedger) -> String {
        return classifyWeightedNetworkQuota(item.measuredValue())
    }
}
