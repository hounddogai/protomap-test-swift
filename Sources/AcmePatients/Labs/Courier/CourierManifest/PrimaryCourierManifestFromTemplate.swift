import AcmePlatform
import Foundation

extension Labs {
    static func summarizePendingPanelTemplatesForManifest(_ items: [PendingPanelTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func derivePrimaryCourierManifestsFromTemplate(_ items: [PendingPanelTemplate]) -> [PrimaryCourierManifest] {
        var out: [PrimaryCourierManifest] = []
        for item in items {
            let derived = newPrimaryCourierManifest(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settlePrimaryCourierManifest(_ item: PrimaryCourierManifest) -> String {
        return normalizeScheduledPanelGroupCode(item.code)
    }
}
