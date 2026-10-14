import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentBundlesForBatch(_ items: [AssessmentBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveAssessmentBatchesFromBundle(_ items: [AssessmentBundle]) -> [AssessmentBatch] {
        var out: [AssessmentBatch] = []
        for item in items {
            let derived = newAssessmentBatch(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveAssessmentBatch(_ item: AssessmentBatch) -> Double {
        return weightedAssessmentBudgetWeight(3, active: true)
    }
}
