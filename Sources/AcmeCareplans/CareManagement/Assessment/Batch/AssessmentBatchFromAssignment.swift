import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeTieredCareGapAssignmentsForBatch(_ items: [TieredCareGapAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveAssessmentBatchesFromAssignment(_ items: [TieredCareGapAssignment]) -> [AssessmentBatch] {
        var out: [AssessmentBatch] = []
        for item in items {
            let derived = newAssessmentBatch(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeAssessmentBatch(_ item: AssessmentBatch) -> String {
        return normalizeCareGapCheckpointCode(item.code)
    }
}
