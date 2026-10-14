import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRegionalPanelDigestsForManifest(_ items: [RegionalPanelDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func derivePanelManifestsFromDigest(_ items: [RegionalPanelDigest]) -> [PanelManifest] {
        var out: [PanelManifest] = []
        for item in items {
            let derived = newPanelManifest(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocatePanelManifest(_ item: PanelManifest) -> String {
        return cappedPanelWindowBucket(item.weightedExposure())
    }
}
