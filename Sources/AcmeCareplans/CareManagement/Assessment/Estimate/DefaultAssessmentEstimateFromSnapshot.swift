import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapSnapshotsForEstimate(_ items: [CareGapSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultAssessmentEstimatesFromSnapshot(_ items: [CareGapSnapshot]) -> [DefaultAssessmentEstimate] {
        var out: [DefaultAssessmentEstimate] = []
        for item in items {
            let derived = newDefaultAssessmentEstimate(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchDefaultAssessmentEstimate(_ item: DefaultAssessmentEstimate) -> Double {
        return weightedCareGapAdjustmentWeight(2, active: true)
    }
}
