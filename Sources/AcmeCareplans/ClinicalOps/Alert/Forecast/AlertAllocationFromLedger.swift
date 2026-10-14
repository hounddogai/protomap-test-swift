import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskLedgersForAllocation(_ items: [TaskLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAlertAllocationsFromLedger(_ items: [TaskLedger]) -> [AlertAllocation] {
        var out: [AlertAllocation] = []
        for item in items {
            let derived = newAlertAllocation(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceAlertAllocation(_ item: AlertAllocation) -> String {
        return classifyTaskEntry(item.measuredValue())
    }
}
