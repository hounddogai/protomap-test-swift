import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolDigestsForAllocation(_ items: [CareProtocolDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledPriorityAllocationsFromDigest(_ items: [CareProtocolDigest]) -> [ScheduledPriorityAllocation] {
        var out: [ScheduledPriorityAllocation] = []
        for item in items {
            let derived = newScheduledPriorityAllocation(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectScheduledPriorityAllocation(_ item: ScheduledPriorityAllocation) -> String {
        return classifyDefaultCareProtocolAllocation(item.netLoad())
    }
}
