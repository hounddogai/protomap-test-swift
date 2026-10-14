import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureBundlesForRule(_ items: [DisclosureBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveWitnessRulesFromBundle(_ items: [DisclosureBundle]) -> [WitnessRule] {
        var out: [WitnessRule] = []
        for item in items {
            let derived = newWitnessRule(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveWitnessRule(_ item: WitnessRule) -> String {
        return tieredDisclosureDigestBucket(item.projectedValue())
    }
}
