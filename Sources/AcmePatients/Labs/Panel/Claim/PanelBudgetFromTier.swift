import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelTiersForBudget(_ items: [PanelTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func derivePanelBudgetsFromTier(_ items: [PanelTier]) -> [PanelBudget] {
        var out: [PanelBudget] = []
        for item in items {
            let derived = newPanelBudget(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scorePanelBudget(_ item: PanelBudget) -> String {
        return panelTierBucket(item.netExposure())
    }
}
