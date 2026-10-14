import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceCyclesForRollup(_ items: [RemittanceCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveRemittanceRollupsFromCycle(_ items: [RemittanceCycle]) -> [RemittanceRollup] {
        var out: [RemittanceRollup] = []
        for item in items {
            let derived = newRemittanceRollup(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRemittanceRollup(_ item: RemittanceRollup) -> Double {
        return remittanceCycleWeight(7, active: true)
    }
}
