import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedResultRulesForBaseline(_ items: [CappedResultRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func derivePendingResultBaselinesFromRule(_ items: [CappedResultRule]) -> [PendingResultBaseline] {
        var out: [PendingResultBaseline] = []
        for item in items {
            let derived = newPendingResultBaseline(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimatePendingResultBaseline(_ item: PendingResultBaseline) -> Double {
        return cappedResultRuleWeight(9, active: true)
    }
}
