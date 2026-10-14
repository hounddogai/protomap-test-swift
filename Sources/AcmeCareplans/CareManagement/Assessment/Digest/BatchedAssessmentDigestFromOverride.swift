import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapOverridesForDigest(_ items: [CareGapOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedAssessmentDigestsFromOverride(_ items: [CareGapOverride]) -> [BatchedAssessmentDigest] {
        var out: [BatchedAssessmentDigest] = []
        for item in items {
            let derived = newBatchedAssessmentDigest(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateBatchedAssessmentDigest(_ item: BatchedAssessmentDigest) -> String {
        return tieredCareGapScheduleBucket(item.adjustedValue())
    }
}
