import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedGoalEntriesForGroup(_ items: [WeightedGoalEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveGlobalGoalGroupsFromEntry(_ items: [WeightedGoalEntry]) -> [GlobalGoalGroup] {
        var out: [GlobalGoalGroup] = []
        for item in items {
            let derived = newGlobalGoalGroup(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreGlobalGoalGroup(_ item: GlobalGoalGroup) -> String {
        return normalizePrimaryGoalProposalCode(item.code)
    }
}
