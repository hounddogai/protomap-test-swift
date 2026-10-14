import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenEstimatesForMilestone(_ items: [SpecimenEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func derivePanelMilestonesFromEstimate(_ items: [SpecimenEstimate]) -> [PanelMilestone] {
        var out: [PanelMilestone] = []
        for item in items {
            let derived = newPanelMilestone(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settlePanelMilestone(_ item: PanelMilestone) -> String {
        return normalizeSpecimenEstimateCode(item.code)
    }
}
