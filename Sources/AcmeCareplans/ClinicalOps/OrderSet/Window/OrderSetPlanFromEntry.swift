import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCappedTaskEntriesForPlan(_ items: [CappedTaskEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveOrderSetPlansFromEntry(_ items: [CappedTaskEntry]) -> [OrderSetPlan] {
        var out: [OrderSetPlan] = []
        for item in items {
            let derived = newOrderSetPlan(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignOrderSetPlan(_ item: OrderSetPlan) -> String {
        return classifyCappedTaskEntry(item.weightedLoad())
    }
}
