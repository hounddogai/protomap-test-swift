import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRollingCareProtocolManifestsForReview(_ items: [RollingCareProtocolManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveBatchedModalityReviewsFromManifest(_ items: [RollingCareProtocolManifest]) -> [BatchedModalityReview] {
        var out: [BatchedModalityReview] = []
        for item in items {
            let derived = newBatchedModalityReview(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeBatchedModalityReview(_ item: BatchedModalityReview) -> String {
        return classifyRollingCareProtocolManifest(item.measuredValue())
    }
}
