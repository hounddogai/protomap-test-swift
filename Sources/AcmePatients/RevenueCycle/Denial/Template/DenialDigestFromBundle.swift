import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRegionalClaimBundlesForDigest(_ items: [RegionalClaimBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveDenialDigestsFromBundle(_ items: [RegionalClaimBundle]) -> [DenialDigest] {
        var out: [DenialDigest] = []
        for item in items {
            let derived = newDenialDigest(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeDenialDigest(_ item: DenialDigest) -> String {
        return classifyRegionalClaimBundle(item.projectedValue())
    }
}
