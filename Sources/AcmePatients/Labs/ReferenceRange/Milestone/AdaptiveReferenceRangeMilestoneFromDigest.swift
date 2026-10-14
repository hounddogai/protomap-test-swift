import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptivePanelDigestsForMilestone(_ items: [AdaptivePanelDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveAdaptiveReferenceRangeMilestonesFromDigest(_ items: [AdaptivePanelDigest]) -> [AdaptiveReferenceRangeMilestone] {
        var out: [AdaptiveReferenceRangeMilestone] = []
        for item in items {
            let derived = newAdaptiveReferenceRangeMilestone(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectAdaptiveReferenceRangeMilestone(_ item: AdaptiveReferenceRangeMilestone) -> Double {
        return panelDraftWeight(4, active: true)
    }
}
