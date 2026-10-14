import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeManualChargeMappingsForSummary(_ items: [ManualChargeMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveWeightedStatementSummariesFromMapping(_ items: [ManualChargeMapping]) -> [WeightedStatementSummary] {
        var out: [WeightedStatementSummary] = []
        for item in items {
            let derived = newWeightedStatementSummary(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveWeightedStatementSummary(_ item: WeightedStatementSummary) -> String {
        return chargeBaselineBucket(item.measuredValue())
    }
}
