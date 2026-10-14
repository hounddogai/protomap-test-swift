import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRegionalModalitySlotsForBudget(_ items: [RegionalModalitySlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveRollingPriorityBudgetsFromSlot(_ items: [RegionalModalitySlot]) -> [RollingPriorityBudget] {
        var out: [RollingPriorityBudget] = []
        for item in items {
            let derived = newRollingPriorityBudget(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeRollingPriorityBudget(_ item: RollingPriorityBudget) -> Double {
        return regionalModalitySlotWeight(9, active: true)
    }
}
