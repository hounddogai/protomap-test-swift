import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptivePanelSnapshotsForMilestone(_ items: [AdaptivePanelSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveReferenceRangeMilestonesFromSnapshot(_ items: [AdaptivePanelSnapshot]) -> [ReferenceRangeMilestone] {
        var out: [ReferenceRangeMilestone] = []
        for item in items {
            let derived = newReferenceRangeMilestone(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleReferenceRangeMilestone(_ item: ReferenceRangeMilestone) -> String {
        return normalizeGlobalPanelTemplateCode(item.code)
    }
}
