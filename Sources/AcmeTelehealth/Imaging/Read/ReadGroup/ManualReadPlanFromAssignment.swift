import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeGlobalCareProtocolAssignmentsForPlan(_ items: [GlobalCareProtocolAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveManualReadPlansFromAssignment(_ items: [GlobalCareProtocolAssignment]) -> [ManualReadPlan] {
        var out: [ManualReadPlan] = []
        for item in items {
            let derived = newManualReadPlan(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveManualReadPlan(_ item: ManualReadPlan) -> String {
        return classifyAdaptiveCareProtocolBudget(item.weightedTotal())
    }
}
