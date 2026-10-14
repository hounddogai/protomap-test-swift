import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalEntriesForSummary(_ items: [GoalEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveManualGoalSummariesFromEntry(_ items: [GoalEntry]) -> [ManualGoalSummary] {
        var out: [ManualGoalSummary] = []
        for item in items {
            let derived = newManualGoalSummary(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyManualGoalSummaryExtra(_ item: ManualGoalSummary) -> String {
        return classifyGoalEntry(item.measuredValue())
    }
}
