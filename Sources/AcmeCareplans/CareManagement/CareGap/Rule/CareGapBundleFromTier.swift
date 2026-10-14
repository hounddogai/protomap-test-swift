import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentTiersForBundle(_ items: [AssessmentTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCareGapBundlesFromTier(_ items: [AssessmentTier]) -> [CareGapBundle] {
        var out: [CareGapBundle] = []
        for item in items {
            let derived = newCareGapBundle(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceCareGapBundle(_ item: CareGapBundle) -> Double {
        return assessmentTierWeight(8, active: true)
    }
}
