import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimePlansForAllocation(_ items: [OvertimePlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveGlobalShiftAllocationsFromPlan(_ items: [OvertimePlan]) -> [GlobalShiftAllocation] {
        var out: [GlobalShiftAllocation] = []
        for item in items {
            let derived = newGlobalShiftAllocation(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleGlobalShiftAllocation(_ item: GlobalShiftAllocation) -> Double {
        return overtimePlanWeight(6, active: true)
    }
}
