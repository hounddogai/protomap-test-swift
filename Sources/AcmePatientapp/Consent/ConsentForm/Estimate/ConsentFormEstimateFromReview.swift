import AcmePlatform
import Foundation

extension Consent {
    static func summarizeScheduledRevocationReviewsForEstimate(_ items: [ScheduledRevocationReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveConsentFormEstimatesFromReview(_ items: [ScheduledRevocationReview]) -> [ConsentFormEstimate] {
        var out: [ConsentFormEstimate] = []
        for item in items {
            let derived = newConsentFormEstimate(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyConsentFormEstimate(_ item: ConsentFormEstimate) -> String {
        return classifyRevocationLedger(item.projectedExposure())
    }
}
