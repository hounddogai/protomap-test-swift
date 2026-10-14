import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachReviewsForMilestone(_ items: [OutreachReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveCareGapMilestonesFromReview(_ items: [OutreachReview]) -> [CareGapMilestone] {
        var out: [CareGapMilestone] = []
        for item in items {
            let derived = newCareGapMilestone(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankCareGapMilestone(_ item: CareGapMilestone) -> String {
        return normalizeOutreachTargetCode(item.code)
    }
}
