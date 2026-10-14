import AcmePlatform
import Foundation

extension Labs {
    static func summarizeStrictReferenceRangeScoresForMilestone(_ items: [StrictReferenceRangeScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func derivePendingPanelMilestonesFromScore(_ items: [StrictReferenceRangeScore]) -> [PendingPanelMilestone] {
        var out: [PendingPanelMilestone] = []
        for item in items {
            let derived = newPendingPanelMilestone(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergePendingPanelMilestone(_ item: PendingPanelMilestone) -> String {
        return referenceRangeGroupBucket(item.effectiveTotal())
    }
}
