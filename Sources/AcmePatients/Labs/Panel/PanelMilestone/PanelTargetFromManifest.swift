import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultResultManifestsForTarget(_ items: [DefaultResultManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func derivePanelTargetsFromManifest(_ items: [DefaultResultManifest]) -> [PanelTarget] {
        var out: [PanelTarget] = []
        for item in items {
            let derived = newPanelTarget(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balancePanelTarget(_ item: PanelTarget) -> String {
        return fallbackResultPreferenceBucket(item.weightedValue())
    }
}
