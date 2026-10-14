import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeWeightedRecallBundlesForMapping(_ items: [WeightedRecallBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveFallbackDispenseMappingsFromBundle(_ items: [WeightedRecallBundle]) -> [FallbackDispenseMapping] {
        var out: [FallbackDispenseMapping] = []
        for item in items {
            let derived = newFallbackDispenseMapping(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignFallbackDispenseMapping(_ item: FallbackDispenseMapping) -> String {
        return normalizeWeightedRecallBundleCode(item.code)
    }
}
