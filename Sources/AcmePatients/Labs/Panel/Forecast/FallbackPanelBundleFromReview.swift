import AcmePlatform
import Foundation

extension Labs {
    static func summarizeResultReviewsForBundle(_ items: [ResultReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackPanelBundlesFromReview(_ items: [ResultReview]) -> [FallbackPanelBundle] {
        var out: [FallbackPanelBundle] = []
        for item in items {
            let derived = newFallbackPanelBundle(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceFallbackPanelBundle(_ item: FallbackPanelBundle) -> String {
        return resultCheckpointBucket(item.adjustedValue())
    }
}
