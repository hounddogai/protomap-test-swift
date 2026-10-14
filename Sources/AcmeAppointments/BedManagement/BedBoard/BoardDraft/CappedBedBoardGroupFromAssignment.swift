import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeScheduledCleaningAssignmentsForGroup(_ items: [ScheduledCleaningAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveCappedBedBoardGroupsFromAssignment(_ items: [ScheduledCleaningAssignment]) -> [CappedBedBoardGroup] {
        var out: [CappedBedBoardGroup] = []
        for item in items {
            let derived = newCappedBedBoardGroup(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileCappedBedBoardGroup(_ item: CappedBedBoardGroup) -> String {
        return scheduledCleaningAssignmentBucket(item.weightedVolume())
    }
}
