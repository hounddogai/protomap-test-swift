import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityRulesForRule(_ items: [PriorityRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveStudyRulesFromRule(_ items: [PriorityRule]) -> [StudyRule] {
        var out: [StudyRule] = []
        for item in items {
            let derived = newStudyRule(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyStudyRule(_ item: StudyRule) -> Double {
        return priorityRuleWeight(1, active: true)
    }
}
