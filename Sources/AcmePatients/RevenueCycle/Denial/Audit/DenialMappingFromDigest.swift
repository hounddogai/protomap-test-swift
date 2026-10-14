import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeDigestsForMapping(_ items: [ChargeDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveDenialMappingsFromDigest(_ items: [ChargeDigest]) -> [DenialMapping] {
        var out: [DenialMapping] = []
        for item in items {
            let derived = newDenialMapping(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleDenialMapping(_ item: DenialMapping) -> String {
        return chargeDigestBucket(item.weightedExposure())
    }
}
