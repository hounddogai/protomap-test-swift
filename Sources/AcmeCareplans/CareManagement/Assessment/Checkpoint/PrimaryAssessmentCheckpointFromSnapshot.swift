import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentSnapshotsForCheckpoint(_ items: [AssessmentSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePrimaryAssessmentCheckpointsFromSnapshot(_ items: [AssessmentSnapshot]) -> [PrimaryAssessmentCheckpoint] {
        var out: [PrimaryAssessmentCheckpoint] = []
        for item in items {
            let derived = newPrimaryAssessmentCheckpoint(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyPrimaryAssessmentCheckpoint(_ item: PrimaryAssessmentCheckpoint) -> String {
        return cappedAssessmentScheduleBucket(item.weightedValue())
    }
}
