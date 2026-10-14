import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePrioritySlotsForPolicy(_ items: [PrioritySlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePriorityPoliciesFromSlot(_ items: [PrioritySlot]) -> [PriorityPolicy] {
        var out: [PriorityPolicy] = []
        for item in items {
            let derived = newPriorityPolicy(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyPriorityPolicy(_ item: PriorityPolicy) -> String {
        return classifyGlobalPriorityAgreement(item.weightedLoad())
    }
}
