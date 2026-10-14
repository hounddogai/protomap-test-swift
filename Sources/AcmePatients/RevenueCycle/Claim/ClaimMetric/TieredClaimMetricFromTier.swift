import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLenientChargeTiersForMetric(_ items: [LenientChargeTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveTieredClaimMetricsFromTier(_ items: [LenientChargeTier]) -> [TieredClaimMetric] {
        var out: [TieredClaimMetric] = []
        for item in items {
            let derived = newTieredClaimMetric(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateTieredClaimMetric(_ item: TieredClaimMetric) -> Double {
        return chargeSegmentWeight(2, active: true)
    }
}
