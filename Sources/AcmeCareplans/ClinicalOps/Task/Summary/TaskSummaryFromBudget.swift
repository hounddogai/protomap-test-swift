import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertBudgetsForSummary(_ items: [AlertBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveTaskSummariesFromBudget(_ items: [AlertBudget]) -> [TaskSummary] {
        var out: [TaskSummary] = []
        for item in items {
            let derived = newTaskSummary(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignTaskSummary(_ item: TaskSummary) -> String {
        return classifyAlertQuota(item.netValue())
    }
}
