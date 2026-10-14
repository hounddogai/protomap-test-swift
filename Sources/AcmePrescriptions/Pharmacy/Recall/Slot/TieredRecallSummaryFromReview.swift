import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFallbackDispenseReviewsForSummary(_ items: [FallbackDispenseReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveTieredRecallSummariesFromReview(_ items: [FallbackDispenseReview]) -> [TieredRecallSummary] {
        var out: [TieredRecallSummary] = []
        for item in items {
            let derived = newTieredRecallSummary(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveTieredRecallSummary(_ item: TieredRecallSummary) -> String {
        return dispenseBaselineBucket(item.measuredValue())
    }
}
