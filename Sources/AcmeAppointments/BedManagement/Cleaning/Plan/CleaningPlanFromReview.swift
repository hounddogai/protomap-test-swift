import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusReviewsForPlan(_ items: [CensusReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveCleaningPlansFromReview(_ items: [CensusReview]) -> [CleaningPlan] {
        var out: [CleaningPlan] = []
        for item in items {
            let derived = newCleaningPlan(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchCleaningPlan(_ item: CleaningPlan) -> Double {
        return censusReviewWeight(4, active: true)
    }
}
