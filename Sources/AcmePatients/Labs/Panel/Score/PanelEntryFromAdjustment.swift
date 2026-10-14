import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionAdjustmentsForEntry(_ items: [AccessionAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func derivePanelEntriesFromAdjustment(_ items: [AccessionAdjustment]) -> [PanelEntry] {
        var out: [PanelEntry] = []
        for item in items {
            let derived = newPanelEntry(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPanelEntry(_ item: PanelEntry) -> String {
        return classifyAccessionRule(item.projectedExposure())
    }
}
