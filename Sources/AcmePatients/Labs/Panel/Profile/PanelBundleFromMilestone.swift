import AcmePlatform
import Foundation

extension Labs {
    static func summarizeGlobalCourierMilestonesForBundle(_ items: [GlobalCourierMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePanelBundlesFromMilestone(_ items: [GlobalCourierMilestone]) -> [PanelBundle] {
        var out: [PanelBundle] = []
        for item in items {
            let derived = newPanelBundle(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyPanelBundle(_ item: PanelBundle) -> String {
        return globalCourierMilestoneBucket(item.projectedLoad())
    }
}
