import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargeRequestsForPolicy(_ items: [ChargeRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveDenialPoliciesFromRequest(_ items: [ChargeRequest]) -> [DenialPolicy] {
        var out: [DenialPolicy] = []
        for item in items {
            let derived = newDenialPolicy(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeDenialPolicy(_ item: DenialPolicy) -> Double {
        return chargeQuotaWeight(3, active: true)
    }
}
