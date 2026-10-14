import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRegionalCareGapBundlesForMilestone(_ items: [RegionalCareGapBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAssessmentMilestonesFromBundle(_ items: [RegionalCareGapBundle]) -> [AssessmentMilestone] {
        var out: [AssessmentMilestone] = []
        for item in items {
            let derived = newAssessmentMilestone(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitAssessmentMilestone(_ item: AssessmentMilestone) -> String {
        return batchedCareGapAssignmentBucket(item.measuredValue())
    }
}
