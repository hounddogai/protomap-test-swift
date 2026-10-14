import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePendingRecallTemplatesForEstimate(_ items: [PendingRecallTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveWeightedFormularyEstimatesFromTemplate(_ items: [PendingRecallTemplate]) -> [WeightedFormularyEstimate] {
        var out: [WeightedFormularyEstimate] = []
        for item in items {
            let derived = newWeightedFormularyEstimate(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyWeightedFormularyEstimate(_ item: WeightedFormularyEstimate) -> String {
        return classifyRollingRecallBaseline(item.projectedExposure())
    }
}
