import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeSeasonalRemittancePoliciesForThreshold(_ items: [SeasonalRemittancePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveChargeThresholdsFromPolicy(_ items: [SeasonalRemittancePolicy]) -> [ChargeThreshold] {
        var out: [ChargeThreshold] = []
        for item in items {
            let derived = newChargeThreshold(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignChargeThreshold(_ item: ChargeThreshold) -> Double {
        return primaryRemittanceRequestWeight(5, active: true)
    }
}
