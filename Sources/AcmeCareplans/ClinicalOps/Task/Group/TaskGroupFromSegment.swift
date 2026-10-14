import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskSegmentsForGroup(_ items: [TaskSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveTaskGroupsFromSegment(_ items: [TaskSegment]) -> [TaskGroup] {
        var out: [TaskGroup] = []
        for item in items {
            let derived = newTaskGroup(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceTaskGroup(_ item: TaskGroup) -> String {
        return normalizeStrictTaskMilestoneCode(item.code)
    }
}
