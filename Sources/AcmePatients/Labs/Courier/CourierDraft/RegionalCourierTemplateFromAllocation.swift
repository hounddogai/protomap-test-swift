import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptivePanelAllocationsForTemplate(_ items: [AdaptivePanelAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveRegionalCourierTemplatesFromAllocation(_ items: [AdaptivePanelAllocation]) -> [RegionalCourierTemplate] {
        var out: [RegionalCourierTemplate] = []
        for item in items {
            let derived = newRegionalCourierTemplate(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileRegionalCourierTemplate(_ item: RegionalCourierTemplate) -> Double {
        return adaptivePanelAllocationWeight(7, active: true)
    }
}
