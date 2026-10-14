import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalConsentFormPlansForDigest(_ items: [GlobalConsentFormPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveSeasonalDisclosureDigestsFromPlan(_ items: [GlobalConsentFormPlan]) -> [SeasonalDisclosureDigest] {
        var out: [SeasonalDisclosureDigest] = []
        for item in items {
            let derived = newSeasonalDisclosureDigest(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifySeasonalDisclosureDigestExtra(_ item: SeasonalDisclosureDigest) -> String {
        return normalizePrimaryConsentFormReviewCode(item.code)
    }
}
