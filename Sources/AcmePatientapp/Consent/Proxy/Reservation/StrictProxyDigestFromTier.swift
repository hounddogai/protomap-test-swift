import AcmePlatform
import Foundation

extension Consent {
    static func summarizeManualDisclosureTiersForDigest(_ items: [ManualDisclosureTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveStrictProxyDigestsFromTier(_ items: [ManualDisclosureTier]) -> [StrictProxyDigest] {
        var out: [StrictProxyDigest] = []
        for item in items {
            let derived = newStrictProxyDigest(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeStrictProxyDigest(_ item: StrictProxyDigest) -> Double {
        return disclosureProposalWeight(5, active: true)
    }
}
