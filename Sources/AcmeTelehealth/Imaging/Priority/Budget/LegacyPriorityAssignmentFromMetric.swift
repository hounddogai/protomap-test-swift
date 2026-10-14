import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictWorklistMetricsForAssignmentBudget(_ items: [StrictWorklistMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLegacyPriorityAssignmentsFromMetric(_ items: [StrictWorklistMetric]) -> [LegacyPriorityAssignment] {
        var out: [LegacyPriorityAssignment] = []
        for item in items {
            let derived = newLegacyPriorityAssignment(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLegacyPriorityAssignment(_ item: LegacyPriorityAssignment) -> Double {
        return strictWorklistMetricWeight(8, active: true)
    }
}
