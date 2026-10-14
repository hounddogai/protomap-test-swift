import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRegionalConsentFormQuotasForTier(_ items: [RegionalConsentFormQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackRevocationTiersFromQuota(_ items: [RegionalConsentFormQuota]) -> [FallbackRevocationTier] {
        var out: [FallbackRevocationTier] = []
        for item in items {
            let derived = newFallbackRevocationTier(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeFallbackRevocationTier(_ item: FallbackRevocationTier) -> Double {
        return cappedConsentFormRollupWeight(4, active: true)
    }
}
