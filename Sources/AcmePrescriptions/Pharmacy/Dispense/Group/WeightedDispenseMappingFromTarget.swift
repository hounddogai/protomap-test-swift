import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeBatchedSubstitutionTargetsForMapping(_ items: [BatchedSubstitutionTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveWeightedDispenseMappingsFromTarget(_ items: [BatchedSubstitutionTarget]) -> [WeightedDispenseMapping] {
        var out: [WeightedDispenseMapping] = []
        for item in items {
            let derived = newWeightedDispenseMapping(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeWeightedDispenseMapping(_ item: WeightedDispenseMapping) -> String {
        return classifyBatchedSubstitutionTarget(item.adjustedExposure())
    }
}
