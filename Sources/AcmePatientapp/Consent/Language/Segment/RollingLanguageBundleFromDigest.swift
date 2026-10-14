import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictProxyDigestsForBundle(_ items: [StrictProxyDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveRollingLanguageBundlesFromDigest(_ items: [StrictProxyDigest]) -> [RollingLanguageBundle] {
        var out: [RollingLanguageBundle] = []
        for item in items {
            let derived = newRollingLanguageBundle(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeRollingLanguageBundle(_ item: RollingLanguageBundle) -> String {
        return strictProxyDigestBucket(item.effectiveTotal())
    }
}
