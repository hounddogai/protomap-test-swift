import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentReviewsForSnapshot(_ items: [AssessmentReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveLegacyCareGapSnapshotsFromReview(_ items: [AssessmentReview]) -> [LegacyCareGapSnapshot] {
        var out: [LegacyCareGapSnapshot] = []
        for item in items {
            let derived = newLegacyCareGapSnapshot(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileLegacyCareGapSnapshot(_ item: LegacyCareGapSnapshot) -> String {
        return normalizeAssessmentClaimCode(item.code)
    }
}
