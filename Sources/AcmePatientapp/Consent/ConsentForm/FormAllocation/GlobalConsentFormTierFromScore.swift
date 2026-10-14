import AcmePlatform
import Foundation

extension Consent {
    static func summarizeCappedRevocationScoresForTier(_ items: [CappedRevocationScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveGlobalConsentFormTiersFromScore(_ items: [CappedRevocationScore]) -> [GlobalConsentFormTier] {
        var out: [GlobalConsentFormTier] = []
        for item in items {
            let derived = newGlobalConsentFormTier(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveGlobalConsentFormTier(_ item: GlobalConsentFormTier) -> String {
        return normalizeLenientRevocationSummaryCode(item.code)
    }
}
