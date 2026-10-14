import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeTieredStatementAdjustmentsForThreshold(_ items: [TieredStatementAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveRollingDenialThresholdsFromAdjustment(_ items: [TieredStatementAdjustment]) -> [RollingDenialThreshold] {
        var out: [RollingDenialThreshold] = []
        for item in items {
            let derived = newRollingDenialThreshold(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeRollingDenialThreshold(_ item: RollingDenialThreshold) -> Double {
        return tieredStatementAdjustmentWeight(1, active: true)
    }
}
