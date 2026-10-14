import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCappedOrderSetPlansForMapping(_ items: [CappedOrderSetPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveLegacyRoundingMappingsFromPlan(_ items: [CappedOrderSetPlan]) -> [LegacyRoundingMapping] {
        var out: [LegacyRoundingMapping] = []
        for item in items {
            let derived = newLegacyRoundingMapping(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitLegacyRoundingMapping(_ item: LegacyRoundingMapping) -> String {
        return classifyCappedOrderSetPlan(item.effectiveExposure())
    }
}
