import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentMilestonesForThreshold(_ items: [AssessmentMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientOutreachThresholdsFromMilestone(_ items: [AssessmentMilestone]) -> [LenientOutreachThreshold] {
        var out: [LenientOutreachThreshold] = []
        for item in items {
            let derived = newLenientOutreachThreshold(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeLenientOutreachThreshold(_ item: LenientOutreachThreshold) -> String {
        return assessmentMilestoneBucket(item.netTotal())
    }
}
