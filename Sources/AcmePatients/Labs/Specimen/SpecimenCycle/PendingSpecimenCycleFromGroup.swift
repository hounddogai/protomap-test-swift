import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLenientCourierGroupsForCycle(_ items: [LenientCourierGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingSpecimenCyclesFromGroup(_ items: [LenientCourierGroup]) -> [PendingSpecimenCycle] {
        var out: [PendingSpecimenCycle] = []
        for item in items {
            let derived = newPendingSpecimenCycle(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimatePendingSpecimenCycle(_ item: PendingSpecimenCycle) -> String {
        return lenientCourierGroupBucket(item.effectiveTotal())
    }
}
