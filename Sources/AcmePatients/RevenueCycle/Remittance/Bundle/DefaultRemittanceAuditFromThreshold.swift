import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeWeightedChargeThresholdsForAudit(_ items: [WeightedChargeThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveDefaultRemittanceAuditsFromThreshold(_ items: [WeightedChargeThreshold]) -> [DefaultRemittanceAudit] {
        var out: [DefaultRemittanceAudit] = []
        for item in items {
            let derived = newDefaultRemittanceAudit(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeDefaultRemittanceAudit(_ item: DefaultRemittanceAudit) -> Double {
        return weightedChargeThresholdWeight(2, active: true)
    }
}
