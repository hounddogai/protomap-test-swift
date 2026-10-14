import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeRegionalIsolationDraftsForScore(_ items: [RegionalIsolationDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveDischargePlanScoresFromDraft(_ items: [RegionalIsolationDraft]) -> [DischargePlanScore] {
        var out: [DischargePlanScore] = []
        for item in items {
            let derived = newDischargePlanScore(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeDischargePlanScore(_ item: DischargePlanScore) -> String {
        return classifyIsolationTarget(item.effectiveVolume())
    }
}
