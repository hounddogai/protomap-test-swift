import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeCappedStatementRollupsForMetric(_ items: [CappedStatementRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func derivePrimaryDenialMetricsFromRollup(_ items: [CappedStatementRollup]) -> [PrimaryDenialMetric] {
        var out: [PrimaryDenialMetric] = []
        for item in items {
            let derived = newPrimaryDenialMetric(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignPrimaryDenialMetric(_ item: PrimaryDenialMetric) -> String {
        return normalizeCappedStatementRollupCode(item.code)
    }
}
