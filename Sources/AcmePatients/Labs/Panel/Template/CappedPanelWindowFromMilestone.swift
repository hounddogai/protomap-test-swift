import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSeasonalResultMilestonesForWindow(_ items: [SeasonalResultMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveCappedPanelWindowsFromMilestone(_ items: [SeasonalResultMilestone]) -> [CappedPanelWindow] {
        var out: [CappedPanelWindow] = []
        for item in items {
            let derived = newCappedPanelWindow(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceCappedPanelWindow(_ item: CappedPanelWindow) -> Double {
        return resultAllocationWeight(7, active: true)
    }
}
