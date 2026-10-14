import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingFormularyRulesForBaseline(_ items: [RollingFormularyRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRollingRecallBaselinesFromRule(_ items: [RollingFormularyRule]) -> [RollingRecallBaseline] {
        var out: [RollingRecallBaseline] = []
        for item in items {
            let derived = newRollingRecallBaseline(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceRollingRecallBaseline(_ item: RollingRecallBaseline) -> String {
        return normalizeRollingFormularyRuleCode(item.code)
    }
}
