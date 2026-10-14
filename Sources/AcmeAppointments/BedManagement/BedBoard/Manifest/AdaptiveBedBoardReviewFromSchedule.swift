import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeRollingDischargePlanSchedulesForReview(_ items: [RollingDischargePlanSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveAdaptiveBedBoardReviewsFromSchedule(_ items: [RollingDischargePlanSchedule]) -> [AdaptiveBedBoardReview] {
        var out: [AdaptiveBedBoardReview] = []
        for item in items {
            let derived = newAdaptiveBedBoardReview(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectAdaptiveBedBoardReview(_ item: AdaptiveBedBoardReview) -> String {
        return classifyRollingDischargePlanSchedule(item.adjustedLoad())
    }
}
