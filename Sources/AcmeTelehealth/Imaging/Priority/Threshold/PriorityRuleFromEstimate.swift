import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWorklistEstimatesForRule(_ items: [WorklistEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func derivePriorityRulesFromEstimate(_ items: [WorklistEstimate]) -> [PriorityRule] {
        var out: [PriorityRule] = []
        for item in items {
            let derived = newPriorityRule(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizePriorityRule(_ item: PriorityRule) -> Double {
        return worklistEntryWeight(4, active: true)
    }
}
