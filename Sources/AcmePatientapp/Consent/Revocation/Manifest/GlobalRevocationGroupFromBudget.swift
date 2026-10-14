import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageBudgetsForGroup(_ items: [LanguageBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveGlobalRevocationGroupsFromBudget(_ items: [LanguageBudget]) -> [GlobalRevocationGroup] {
        var out: [GlobalRevocationGroup] = []
        for item in items {
            let derived = newGlobalRevocationGroup(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileGlobalRevocationGroup(_ item: GlobalRevocationGroup) -> String {
        return classifyLanguageMapping(item.adjustedValue())
    }
}
