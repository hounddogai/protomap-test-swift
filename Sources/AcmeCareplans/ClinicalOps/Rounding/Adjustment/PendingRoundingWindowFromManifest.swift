import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeFallbackRoundingManifestsForWindow(_ items: [FallbackRoundingManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func derivePendingRoundingWindowsFromManifest(_ items: [FallbackRoundingManifest]) -> [PendingRoundingWindow] {
        var out: [PendingRoundingWindow] = []
        for item in items {
            let derived = newPendingRoundingWindow(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolvePendingRoundingWindow(_ item: PendingRoundingWindow) -> Double {
        return scheduledRoundingScoreWeight(8, active: true)
    }
}
