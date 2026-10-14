import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRegionalWitnessBudgetsForQuota(_ items: [RegionalWitnessBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedWitnessQuotasFromBudget(_ items: [RegionalWitnessBudget]) -> [BatchedWitnessQuota] {
        var out: [BatchedWitnessQuota] = []
        for item in items {
            let derived = newBatchedWitnessQuota(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeBatchedWitnessQuota(_ item: BatchedWitnessQuota) -> String {
        return normalizeWitnessAdjustmentCode(item.code)
    }
}
