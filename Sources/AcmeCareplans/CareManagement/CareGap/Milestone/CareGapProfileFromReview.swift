import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapReviewsForProfile(_ items: [CareGapReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveCareGapProfilesFromReview(_ items: [CareGapReview]) -> [CareGapProfile] {
        var out: [CareGapProfile] = []
        for item in items {
            let derived = newCareGapProfile(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileCareGapProfile(_ item: CareGapProfile) -> String {
        return normalizeCareGapAllocationCode(item.code)
    }
}
