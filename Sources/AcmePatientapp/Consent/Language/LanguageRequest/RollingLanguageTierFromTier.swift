import AcmePlatform
import Foundation

extension Consent {
    static func summarizeGlobalConsentFormTiersForTier(_ items: [GlobalConsentFormTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRollingLanguageTiersFromTier(_ items: [GlobalConsentFormTier]) -> [RollingLanguageTier] {
        var out: [RollingLanguageTier] = []
        for item in items {
            let derived = newRollingLanguageTier(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeRollingLanguageTier(_ item: RollingLanguageTier) -> String {
        return normalizePendingConsentFormAllocationCode(item.code)
    }
}
