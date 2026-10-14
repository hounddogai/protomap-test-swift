import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistAssignmentsForAudit(_ items: [WorklistAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveWorklistAuditsFromAssignment(_ items: [WorklistAssignment]) -> [WorklistAudit] {
        var out: [WorklistAudit] = []
        for item in items {
            let derived = newWorklistAudit(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreWorklistAudit(_ item: WorklistAudit) -> Double {
        return worklistPreferenceWeight(3, active: true)
    }
}
