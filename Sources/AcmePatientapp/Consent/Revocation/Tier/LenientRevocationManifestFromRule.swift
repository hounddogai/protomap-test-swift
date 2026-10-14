import AcmePlatform
import Foundation

extension Consent {
    static func summarizeCappedConsentFormRulesForManifest(_ items: [CappedConsentFormRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveLenientRevocationManifestsFromRule(_ items: [CappedConsentFormRule]) -> [LenientRevocationManifest] {
        var out: [LenientRevocationManifest] = []
        for item in items {
            let derived = newLenientRevocationManifest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyLenientRevocationManifestExtra(_ item: LenientRevocationManifest) -> String {
        return consentFormBudgetBucket(item.netExposure())
    }
}
