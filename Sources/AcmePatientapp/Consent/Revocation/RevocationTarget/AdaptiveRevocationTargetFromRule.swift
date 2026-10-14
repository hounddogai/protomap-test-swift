import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRevocationRulesForTarget(_ items: [RevocationRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveAdaptiveRevocationTargetsFromRule(_ items: [RevocationRule]) -> [AdaptiveRevocationTarget] {
        var out: [AdaptiveRevocationTarget] = []
        for item in items {
            let derived = newAdaptiveRevocationTarget(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeAdaptiveRevocationTarget(_ item: AdaptiveRevocationTarget) -> String {
        return revocationRuleBucket(item.effectiveLoad())
    }
}
