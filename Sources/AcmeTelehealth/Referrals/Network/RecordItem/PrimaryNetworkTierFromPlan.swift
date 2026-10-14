import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeGlobalEligibilityPlansForTier(_ items: [GlobalEligibilityPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryNetworkTiersFromPlan(_ items: [GlobalEligibilityPlan]) -> [PrimaryNetworkTier] {
        var out: [PrimaryNetworkTier] = []
        for item in items {
            let derived = newPrimaryNetworkTier(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settlePrimaryNetworkTier(_ item: PrimaryNetworkTier) -> Double {
        return eligibilityRequestWeight(7, active: true)
    }
}
