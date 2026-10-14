import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenMilestonesForScore(_ items: [SpecimenMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePanelScoresFromMilestone(_ items: [SpecimenMilestone]) -> [PanelScore] {
        var out: [PanelScore] = []
        for item in items {
            let derived = newPanelScore(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scorePanelScore(_ item: PanelScore) -> String {
        return specimenPlanBucket(item.netExposure())
    }
}
