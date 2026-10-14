import AcmePlatform
import Foundation

extension Consent {
    static func summarizeCappedConsentFormPlansForTier(_ items: [CappedConsentFormPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveSeasonalDisclosureTiersFromPlan(_ items: [CappedConsentFormPlan]) -> [SeasonalDisclosureTier] {
        var out: [SeasonalDisclosureTier] = []
        for item in items {
            let derived = newSeasonalDisclosureTier(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planSeasonalDisclosureTier(_ item: SeasonalDisclosureTier) -> String {
        return rollingConsentFormReviewBucket(item.projectedTotal())
    }
}
