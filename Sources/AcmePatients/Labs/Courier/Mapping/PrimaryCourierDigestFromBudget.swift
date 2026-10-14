import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultResultBudgetsForDigest(_ items: [DefaultResultBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func derivePrimaryCourierDigestsFromBudget(_ items: [DefaultResultBudget]) -> [PrimaryCourierDigest] {
        var out: [PrimaryCourierDigest] = []
        for item in items {
            let derived = newPrimaryCourierDigest(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectPrimaryCourierDigest(_ item: PrimaryCourierDigest) -> String {
        return classifyWeightedResultRule(item.effectiveLoad())
    }
}
