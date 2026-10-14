import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialCyclesForClaim(_ items: [DenialCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveChargeClaimsFromCycle(_ items: [DenialCycle]) -> [ChargeClaim] {
        var out: [ChargeClaim] = []
        for item in items {
            let derived = newChargeClaim(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectChargeClaim(_ item: ChargeClaim) -> String {
        return denialRuleBucket(item.measuredValue())
    }
}
