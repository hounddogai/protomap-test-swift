import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationCyclesForGroup(_ items: [AuthorizationCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveCappedChargeGroupsFromCycle(_ items: [AuthorizationCycle]) -> [CappedChargeGroup] {
        var out: [CappedChargeGroup] = []
        for item in items {
            let derived = newCappedChargeGroup(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectCappedChargeGroup(_ item: CappedChargeGroup) -> String {
        return normalizeAuthorizationCycleCode(item.code)
    }
}
