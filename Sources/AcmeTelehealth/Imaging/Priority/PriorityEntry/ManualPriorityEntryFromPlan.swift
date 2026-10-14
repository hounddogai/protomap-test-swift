import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeManualReadPlansForEntry(_ items: [ManualReadPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveManualPriorityEntriesFromPlan(_ items: [ManualReadPlan]) -> [ManualPriorityEntry] {
        var out: [ManualPriorityEntry] = []
        for item in items {
            let derived = newManualPriorityEntry(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveManualPriorityEntry(_ item: ManualPriorityEntry) -> String {
        return seasonalReadGroupBucket(item.adjustedTotal())
    }
}
