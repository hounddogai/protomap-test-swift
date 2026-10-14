import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingTaskSchedulesForEntry(_ items: [PendingTaskSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveDefaultRoundingEntriesFromSchedule(_ items: [PendingTaskSchedule]) -> [DefaultRoundingEntry] {
        var out: [DefaultRoundingEntry] = []
        for item in items {
            let derived = newDefaultRoundingEntry(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceDefaultRoundingEntry(_ item: DefaultRoundingEntry) -> String {
        return classifyPendingTaskSchedule(item.projectedLoad())
    }
}
