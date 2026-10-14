import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeWeightedEligibilityBundlesForMetric(_ items: [WeightedEligibilityBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackEligibilityMetricsFromBundle(_ items: [WeightedEligibilityBundle]) -> [FallbackEligibilityMetric] {
        var out: [FallbackEligibilityMetric] = []
        for item in items {
            let derived = newFallbackEligibilityMetric(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyFallbackEligibilityMetric(_ item: FallbackEligibilityMetric) -> String {
        return normalizeEligibilityRollupCode(item.code)
    }
}
