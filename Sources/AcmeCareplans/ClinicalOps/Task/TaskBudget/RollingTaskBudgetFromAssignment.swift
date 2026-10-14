import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeGlobalOrderSetAssignmentsForBudget(_ items: [GlobalOrderSetAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveRollingTaskBudgetsFromAssignment(_ items: [GlobalOrderSetAssignment]) -> [RollingTaskBudget] {
        var out: [RollingTaskBudget] = []
        for item in items {
            let derived = newRollingTaskBudget(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileRollingTaskBudget(_ item: RollingTaskBudget) -> String {
        return normalizeGlobalOrderSetAssignmentCode(item.code)
    }
}
