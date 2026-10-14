import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningBudgetsForSchedule(_ items: [CleaningBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveIsolationSchedulesFromBudget(_ items: [CleaningBudget]) -> [IsolationSchedule] {
        var out: [IsolationSchedule] = []
        for item in items {
            let derived = newIsolationSchedule(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveIsolationSchedule(_ item: IsolationSchedule) -> String {
        return classifyCleaningBudget(item.projectedLoad())
    }
}
