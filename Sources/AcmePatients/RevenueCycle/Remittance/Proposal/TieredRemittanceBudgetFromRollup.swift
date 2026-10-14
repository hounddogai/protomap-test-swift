import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDefaultClaimRollupsForBudget(_ items: [DefaultClaimRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveTieredRemittanceBudgetsFromRollup(_ items: [DefaultClaimRollup]) -> [TieredRemittanceBudget] {
        var out: [TieredRemittanceBudget] = []
        for item in items {
            let derived = newTieredRemittanceBudget(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeTieredRemittanceBudget(_ item: TieredRemittanceBudget) -> String {
        return regionalClaimScoreBucket(item.effectiveValue())
    }
}
