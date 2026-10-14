import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWitnessBudgetsForCycle(_ items: [WitnessBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveBatchedDisclosureCyclesFromBudget(_ items: [WitnessBudget]) -> [BatchedDisclosureCycle] {
        var out: [BatchedDisclosureCycle] = []
        for item in items {
            let derived = newBatchedDisclosureCycle(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyBatchedDisclosureCycle(_ item: BatchedDisclosureCycle) -> String {
        return normalizeWitnessBudgetCode(item.code)
    }
}
