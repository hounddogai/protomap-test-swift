import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolDigestsForBudget(_ items: [FloatPoolDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveFloatPoolBudgetsFromDigest(_ items: [FloatPoolDigest]) -> [FloatPoolBudget] {
        var out: [FloatPoolBudget] = []
        for item in items {
            let derived = newFloatPoolBudget(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleFloatPoolBudget(_ item: FloatPoolBudget) -> String {
        return classifyFloatPoolOverride(item.effectiveTotal())
    }
}
