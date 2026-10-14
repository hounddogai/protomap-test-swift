import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeSeasonalAssessmentSnapshotsForRollup(_ items: [SeasonalAssessmentSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveCareGapRollupsFromSnapshot(_ items: [SeasonalAssessmentSnapshot]) -> [CareGapRollup] {
        var out: [CareGapRollup] = []
        for item in items {
            let derived = newCareGapRollup(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignCareGapRollup(_ item: CareGapRollup) -> Double {
        return assessmentTemplateWeight(1, active: true)
    }
}
