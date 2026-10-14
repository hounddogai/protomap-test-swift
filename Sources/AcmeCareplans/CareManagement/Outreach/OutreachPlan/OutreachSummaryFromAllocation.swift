import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalAllocationsForSummary(_ items: [GoalAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveOutreachSummariesFromAllocation(_ items: [GoalAllocation]) -> [OutreachSummary] {
        var out: [OutreachSummary] = []
        for item in items {
            let derived = newOutreachSummary(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignOutreachSummary(_ item: OutreachSummary) -> Double {
        return goalAllocationWeight(4, active: true)
    }
}
