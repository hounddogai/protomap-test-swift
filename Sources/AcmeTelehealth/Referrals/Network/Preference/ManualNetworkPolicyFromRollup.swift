import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeManualClosureRollupsForPolicy(_ items: [ManualClosureRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualNetworkPoliciesFromRollup(_ items: [ManualClosureRollup]) -> [ManualNetworkPolicy] {
        var out: [ManualNetworkPolicy] = []
        for item in items {
            let derived = newManualNetworkPolicy(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchManualNetworkPolicy(_ item: ManualNetworkPolicy) -> Double {
        return strictClosureReservationWeight(1, active: true)
    }
}
