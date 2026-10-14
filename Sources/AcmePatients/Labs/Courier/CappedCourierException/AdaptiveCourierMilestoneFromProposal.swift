import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelProposalsForMilestone(_ items: [PanelProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveAdaptiveCourierMilestonesFromProposal(_ items: [PanelProposal]) -> [AdaptiveCourierMilestone] {
        var out: [AdaptiveCourierMilestone] = []
        for item in items {
            let derived = newAdaptiveCourierMilestone(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyAdaptiveCourierMilestone(_ item: AdaptiveCourierMilestone) -> Double {
        return panelPreferenceWeight(3, active: true)
    }
}
