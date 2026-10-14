import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeRollingDischargePlanScoresForRule(_ items: [RollingDischargePlanScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledBedBoardRulesFromScore(_ items: [RollingDischargePlanScore]) -> [ScheduledBedBoardRule] {
        var out: [ScheduledBedBoardRule] = []
        for item in items {
            let derived = newScheduledBedBoardRule(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeScheduledBedBoardRule(_ item: ScheduledBedBoardRule) -> String {
        return classifyRollingDischargePlanScore(item.adjustedLoad())
    }
}
