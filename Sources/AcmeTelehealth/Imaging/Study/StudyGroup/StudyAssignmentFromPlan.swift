import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeGlobalWorklistPlansForAssignment(_ items: [GlobalWorklistPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveStudyAssignmentsFromPlan(_ items: [GlobalWorklistPlan]) -> [StudyAssignment] {
        var out: [StudyAssignment] = []
        for item in items {
            let derived = newStudyAssignment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreStudyAssignment(_ item: StudyAssignment) -> Double {
        return globalWorklistPlanWeight(4, active: true)
    }
}
