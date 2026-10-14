import AcmePlatform
import Foundation

extension Consent {
    static func summarizeAdaptiveWitnessDigestsForReview(_ items: [AdaptiveWitnessDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveScheduledConsentFormReviewsFromDigest(_ items: [AdaptiveWitnessDigest]) -> [ScheduledConsentFormReview] {
        var out: [ScheduledConsentFormReview] = []
        for item in items {
            let derived = newScheduledConsentFormReview(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateScheduledConsentFormReview(_ item: ScheduledConsentFormReview) -> String {
        return classifyScheduledWitnessProposal(item.weightedLoad())
    }
}
