import AcmePlatform
import Foundation

extension Consent {
    static func summarizeTieredDisclosureDigestsForPolicy(_ items: [TieredDisclosureDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func derivePrimaryProxyPoliciesFromDigest(_ items: [TieredDisclosureDigest]) -> [PrimaryProxyPolicy] {
        var out: [PrimaryProxyPolicy] = []
        for item in items {
            let derived = newPrimaryProxyPolicy(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPrimaryProxyPolicy(_ item: PrimaryProxyPolicy) -> Double {
        return disclosureBundleWeight(6, active: true)
    }
}
