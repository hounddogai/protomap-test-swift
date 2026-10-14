import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRegionalCareGapEstimatesForSegment(_ items: [RegionalCareGapEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveAssessmentSegmentsFromEstimate(_ items: [RegionalCareGapEstimate]) -> [AssessmentSegment] {
        var out: [AssessmentSegment] = []
        for item in items {
            let derived = newAssessmentSegment(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectAssessmentSegment(_ item: AssessmentSegment) -> Double {
        return cappedCareGapAssignmentWeight(3, active: true)
    }
}
