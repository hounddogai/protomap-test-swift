import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientDischargePlanWindowsForGroup(_ items: [LenientDischargePlanWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveCleaningGroupsFromWindow(_ items: [LenientDischargePlanWindow]) -> [CleaningGroup] {
        var out: [CleaningGroup] = []
        for item in items {
            let derived = newCleaningGroup(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleCleaningGroup(_ item: CleaningGroup) -> String {
        return batchedDischargePlanDraftBucket(item.adjustedTotal())
    }
}
