import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeSeasonalCareGapAssignmentsForSnapshot(_ items: [SeasonalCareGapAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveSeasonalAssessmentSnapshotsFromAssignment(_ items: [SeasonalCareGapAssignment]) -> [SeasonalAssessmentSnapshot] {
        var out: [SeasonalAssessmentSnapshot] = []
        for item in items {
            let derived = newSeasonalAssessmentSnapshot(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectSeasonalAssessmentSnapshot(_ item: SeasonalAssessmentSnapshot) -> String {
        return normalizePrimaryCareGapTargetCode(item.code)
    }
}
