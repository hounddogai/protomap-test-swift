import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskRulesForTarget(_ items: [TaskRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualHandoffTargetsFromRule(_ items: [TaskRule]) -> [ManualHandoffTarget] {
        var out: [ManualHandoffTarget] = []
        for item in items {
            let derived = newManualHandoffTarget(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveManualHandoffTarget(_ item: ManualHandoffTarget) -> String {
        return normalizeTaskRuleCode(item.code)
    }
}
