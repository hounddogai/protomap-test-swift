import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelCheckpointsForPreference(_ items: [PanelCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveGlobalResultPreferencesFromCheckpoint(_ items: [PanelCheckpoint]) -> [GlobalResultPreference] {
        var out: [GlobalResultPreference] = []
        for item in items {
            let derived = newGlobalResultPreference(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveGlobalResultPreference(_ item: GlobalResultPreference) -> String {
        return classifyTieredPanelPlan(item.measuredValue())
    }
}
