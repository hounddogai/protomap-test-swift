import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskGroupsForRule(_ items: [TaskGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func derivePrimaryTaskRulesFromGroup(_ items: [TaskGroup]) -> [PrimaryTaskRule] {
        var out: [PrimaryTaskRule] = []
        for item in items {
            let derived = newPrimaryTaskRule(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankPrimaryTaskRule(_ item: PrimaryTaskRule) -> String {
        return normalizeTaskGroupCode(item.code)
    }
}
