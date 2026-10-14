import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalCareProtocolTargetsForReview(_ items: [SeasonalCareProtocolTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveSeasonalOrderSetReviewsFromTarget(_ items: [SeasonalCareProtocolTarget]) -> [SeasonalOrderSetReview] {
        var out: [SeasonalOrderSetReview] = []
        for item in items {
            let derived = newSeasonalOrderSetReview(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreSeasonalOrderSetReview(_ item: SeasonalOrderSetReview) -> String {
        return classifySeasonalCareProtocolTarget(item.weightedValue())
    }
}
