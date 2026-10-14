import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedCareGapWindowsForRequest(_ items: [WeightedCareGapWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveAssessmentRequestsFromWindow(_ items: [WeightedCareGapWindow]) -> [AssessmentRequest] {
        var out: [AssessmentRequest] = []
        for item in items {
            let derived = newAssessmentRequest(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignAssessmentRequest(_ item: AssessmentRequest) -> String {
        return normalizeGlobalCareGapAllocationCode(item.code)
    }
}
