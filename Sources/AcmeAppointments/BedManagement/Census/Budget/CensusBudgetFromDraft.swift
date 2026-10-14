import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningDraftsForBudget(_ items: [CleaningDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveCensusBudgetsFromDraft(_ items: [CleaningDraft]) -> [CensusBudget] {
        var out: [CensusBudget] = []
        for item in items {
            let derived = newCensusBudget(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveCensusBudget(_ item: CensusBudget) -> String {
        return classifyCleaningBudget(item.weightedExposure())
    }
}
