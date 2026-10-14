import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalCredentialTiersForTier(_ items: [SeasonalCredentialTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveRegionalCredentialTiersFromTier(_ items: [SeasonalCredentialTier]) -> [RegionalCredentialTier] {
        var out: [RegionalCredentialTier] = []
        for item in items {
            let derived = newRegionalCredentialTier(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitRegionalCredentialTier(_ item: RegionalCredentialTier) -> String {
        return credentialDigestBucket(item.measuredValue())
    }
}
