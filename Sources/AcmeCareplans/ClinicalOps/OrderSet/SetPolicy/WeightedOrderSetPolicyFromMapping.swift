import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyRoundingMappingsForPolicy(_ items: [LegacyRoundingMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveWeightedOrderSetPoliciesFromMapping(_ items: [LegacyRoundingMapping]) -> [WeightedOrderSetPolicy] {
        var out: [WeightedOrderSetPolicy] = []
        for item in items {
            let derived = newWeightedOrderSetPolicy(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }
}
