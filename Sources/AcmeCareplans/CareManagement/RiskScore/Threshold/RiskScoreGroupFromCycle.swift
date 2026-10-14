import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachCyclesForGroup(_ items: [OutreachCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveRiskScoreGroupsFromCycle(_ items: [OutreachCycle]) -> [RiskScoreGroup] {
        var out: [RiskScoreGroup] = []
        for item in items {
            let derived = newRiskScoreGroup(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchRiskScoreGroup(_ item: RiskScoreGroup) -> String {
        return normalizeOutreachCycleCode(item.code)
    }
}
