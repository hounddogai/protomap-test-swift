import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSeasonalAccessionRollupsForMilestone(_ items: [SeasonalAccessionRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveAdaptivePanelMilestonesFromRollup(_ items: [SeasonalAccessionRollup]) -> [AdaptivePanelMilestone] {
        var out: [AdaptivePanelMilestone] = []
        for item in items {
            let derived = newAdaptivePanelMilestone(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptivePanelMilestone(_ item: AdaptivePanelMilestone) -> String {
        return normalizeAccessionVarianceCode(item.code)
    }
}
