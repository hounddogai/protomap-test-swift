import AcmePlatform
import Foundation

extension Labs {
    static func summarizePendingSpecimenCyclesForBudget(_ items: [PendingSpecimenCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveDefaultResultBudgetsFromCycle(_ items: [PendingSpecimenCycle]) -> [DefaultResultBudget] {
        var out: [DefaultResultBudget] = []
        for item in items {
            let derived = newDefaultResultBudget(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeDefaultResultBudget(_ item: DefaultResultBudget) -> String {
        return lenientSpecimenMilestoneBucket(item.projectedValue())
    }
}
