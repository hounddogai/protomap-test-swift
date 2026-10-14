import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePendingReadBudgetsForAssignment(_ items: [PendingReadBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRollingModalityAssignmentsFromBudget(_ items: [PendingReadBudget]) -> [RollingModalityAssignment] {
        var out: [RollingModalityAssignment] = []
        for item in items {
            let derived = newRollingModalityAssignment(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeRollingModalityAssignment(_ item: RollingModalityAssignment) -> Double {
        return pendingReadBudgetWeight(7, active: true)
    }
}
