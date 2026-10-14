import AcmePlatform
import Foundation

extension Consent {
    static func summarizeSeasonalProxyTargetsForTier(_ items: [SeasonalProxyTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveSeasonalDisclosureTiersFromTarget(_ items: [SeasonalProxyTarget]) -> [SeasonalDisclosureTier] {
        var out: [SeasonalDisclosureTier] = []
        for item in items {
            let derived = newSeasonalDisclosureTier(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeSeasonalDisclosureTier(_ item: SeasonalDisclosureTier) -> String {
        return normalizeBatchedProxyExceptionCode(item.code)
    }
}
