import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeScheduledChargeDigestsForClaim(_ items: [ScheduledChargeDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWeightedChargeClaimsFromDigest(_ items: [ScheduledChargeDigest]) -> [WeightedChargeClaim] {
        var out: [WeightedChargeClaim] = []
        for item in items {
            let derived = newWeightedChargeClaim(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankWeightedChargeClaim(_ item: WeightedChargeClaim) -> String {
        return normalizeScheduledChargeDigestCode(item.code)
    }
}
