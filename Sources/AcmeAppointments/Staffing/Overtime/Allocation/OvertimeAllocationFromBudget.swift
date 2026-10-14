import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeAdaptiveOvertimeBudgetsForAllocation(_ items: [AdaptiveOvertimeBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveOvertimeAllocationsFromBudget(_ items: [AdaptiveOvertimeBudget]) -> [OvertimeAllocation] {
        var out: [OvertimeAllocation] = []
        for item in items {
            let derived = newOvertimeAllocation(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeOvertimeAllocation(_ item: OvertimeAllocation) -> String {
        return normalizeLegacyOvertimePolicyCode(item.code)
    }
}
