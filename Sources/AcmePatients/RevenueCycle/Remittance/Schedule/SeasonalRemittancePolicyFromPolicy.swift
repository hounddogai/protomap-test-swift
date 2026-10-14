import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeChargePoliciesForPolicySchedule(_ items: [ChargePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveSeasonalRemittancePoliciesFromPolicy(_ items: [ChargePolicy]) -> [SeasonalRemittancePolicy] {
        var out: [SeasonalRemittancePolicy] = []
        for item in items {
            let derived = newSeasonalRemittancePolicy(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateSeasonalRemittancePolicy(_ item: SeasonalRemittancePolicy) -> String {
        return classifyFallbackChargeEntry(item.weightedVolume())
    }
}
