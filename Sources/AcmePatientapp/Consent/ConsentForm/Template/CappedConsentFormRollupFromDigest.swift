import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictProxyDigestsForRollup(_ items: [StrictProxyDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveCappedConsentFormRollupsFromDigest(_ items: [StrictProxyDigest]) -> [CappedConsentFormRollup] {
        var out: [CappedConsentFormRollup] = []
        for item in items {
            let derived = newCappedConsentFormRollup(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyCappedConsentFormRollup(_ item: CappedConsentFormRollup) -> String {
        return classifyRegionalProxyManifest(item.effectiveLoad())
    }
}
