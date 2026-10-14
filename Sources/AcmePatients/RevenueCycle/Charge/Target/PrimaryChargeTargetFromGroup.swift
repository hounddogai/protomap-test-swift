import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeCappedChargeGroupsForTarget(_ items: [CappedChargeGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryChargeTargetsFromGroup(_ items: [CappedChargeGroup]) -> [PrimaryChargeTarget] {
        var out: [PrimaryChargeTarget] = []
        for item in items {
            let derived = newPrimaryChargeTarget(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchPrimaryChargeTarget(_ item: PrimaryChargeTarget) -> Double {
        return cappedChargeGroupWeight(7, active: true)
    }
}
