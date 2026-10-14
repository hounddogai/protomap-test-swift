import AcmePlatform
import Foundation

extension Consent {
    static func summarizeBatchedDisclosureCyclesForReview(_ items: [BatchedDisclosureCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveScheduledLanguageReviewsFromCycle(_ items: [BatchedDisclosureCycle]) -> [ScheduledLanguageReview] {
        var out: [ScheduledLanguageReview] = []
        for item in items {
            let derived = newScheduledLanguageReview(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyScheduledLanguageReview(_ item: ScheduledLanguageReview) -> String {
        return batchedDisclosureCycleBucket(item.measuredValue())
    }
}
