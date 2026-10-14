import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredPriorityTargetsForThreshold(_ items: [TieredPriorityTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveLegacyModalityThresholdsFromTarget(_ items: [TieredPriorityTarget]) -> [LegacyModalityThreshold] {
        var out: [LegacyModalityThreshold] = []
        for item in items {
            let derived = newLegacyModalityThreshold(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyLegacyModalityThreshold(_ item: LegacyModalityThreshold) -> String {
        return normalizeTieredPriorityTargetCode(item.code)
    }
}
