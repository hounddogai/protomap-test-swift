import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadSnapshotsForPlan(_ items: [ReadSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePriorityPlansFromSnapshot(_ items: [ReadSnapshot]) -> [PriorityPlan] {
        var out: [PriorityPlan] = []
        for item in items {
            let derived = newPriorityPlan(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignPriorityPlan(_ item: PriorityPlan) -> String {
        return classifyReadMapping(item.effectiveTotal())
    }
}
