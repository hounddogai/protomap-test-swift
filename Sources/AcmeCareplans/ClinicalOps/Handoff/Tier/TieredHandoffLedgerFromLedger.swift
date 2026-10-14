import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeWeightedTaskLedgersForLedger(_ items: [WeightedTaskLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTieredHandoffLedgersFromLedger(_ items: [WeightedTaskLedger]) -> [TieredHandoffLedger] {
        var out: [TieredHandoffLedger] = []
        for item in items {
            let derived = newTieredHandoffLedger(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateTieredHandoffLedger(_ item: TieredHandoffLedger) -> String {
        return normalizeTieredTaskPolicyCode(item.code)
    }
}
