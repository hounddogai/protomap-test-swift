import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultReviewsForVariance(_ items: [ResultReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackReferenceRangeVariancesFromReview(_ items: [ResultReview]) -> [FallbackReferenceRangeVariance] {
        var out: [FallbackReferenceRangeVariance] = []
        for item in items {
            let derived = newFallbackReferenceRangeVariance(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleFallbackReferenceRangeVariance(_ item: FallbackReferenceRangeVariance) -> String {
        return resultCheckpointBucket(item.weightedLoad())
    }
}
