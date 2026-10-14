import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeTieredOutreachSegmentsForMilestone(_ items: [TieredOutreachSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveFallbackAssessmentMilestonesFromSegment(_ items: [TieredOutreachSegment]) -> [FallbackAssessmentMilestone] {
        var out: [FallbackAssessmentMilestone] = []
        for item in items {
            let derived = newFallbackAssessmentMilestone(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreFallbackAssessmentMilestone(_ item: FallbackAssessmentMilestone) -> String {
        return normalizePrimaryOutreachCheckpointCode(item.code)
    }
}
