import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptivePanelAllocationsForDraft(_ items: [AdaptivePanelAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveWeightedPanelDraftsFromAllocation(_ items: [AdaptivePanelAllocation]) -> [WeightedPanelDraft] {
        var out: [WeightedPanelDraft] = []
        for item in items {
            let derived = newWeightedPanelDraft(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyWeightedPanelDraft(_ item: WeightedPanelDraft) -> String {
        return fallbackPanelGroupBucket(item.measuredValue())
    }
}
