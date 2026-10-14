import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardVariancesForBudget(_ items: [BedBoardVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveScheduledCensusBudgetsFromVariance(_ items: [BedBoardVariance]) -> [ScheduledCensusBudget] {
        var out: [ScheduledCensusBudget] = []
        for item in items {
            let derived = newScheduledCensusBudget(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeScheduledCensusBudget(_ item: ScheduledCensusBudget) -> String {
        return normalizeBedBoardOverrideCode(item.code)
    }
}
