import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeWeightedSubstitutionDigestsForMetric(_ items: [WeightedSubstitutionDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveDispenseMetricsFromDigest(_ items: [WeightedSubstitutionDigest]) -> [DispenseMetric] {
        var out: [DispenseMetric] = []
        for item in items {
            let derived = newDispenseMetric(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveDispenseMetric(_ item: DispenseMetric) -> String {
        return substitutionPolicyBucket(item.adjustedVolume())
    }
}
