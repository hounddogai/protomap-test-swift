import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedPanelGroupsForVariance(_ items: [CappedPanelGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func derivePanelVariancesFromGroup(_ items: [CappedPanelGroup]) -> [PanelVariance] {
        var out: [PanelVariance] = []
        for item in items {
            let derived = newPanelVariance(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balancePanelVariance(_ item: PanelVariance) -> Double {
        return panelQuotaWeight(2, active: true)
    }
}
