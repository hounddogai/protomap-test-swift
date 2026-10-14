import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWeightedWorklistTemplatesForEstimate(_ items: [WeightedWorklistTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveManualModalityEstimatesFromTemplate(_ items: [WeightedWorklistTemplate]) -> [ManualModalityEstimate] {
        var out: [ManualModalityEstimate] = []
        for item in items {
            let derived = newManualModalityEstimate(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeManualModalityEstimate(_ item: ManualModalityEstimate) -> String {
        return classifyWorklistWindow(item.effectiveTotal())
    }
}
