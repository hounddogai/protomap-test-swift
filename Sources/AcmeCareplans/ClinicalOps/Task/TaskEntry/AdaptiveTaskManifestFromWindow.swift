import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeFallbackOrderSetWindowsForManifest(_ items: [FallbackOrderSetWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveAdaptiveTaskManifestsFromWindow(_ items: [FallbackOrderSetWindow]) -> [AdaptiveTaskManifest] {
        var out: [AdaptiveTaskManifest] = []
        for item in items {
            let derived = newAdaptiveTaskManifest(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceAdaptiveTaskManifest(_ item: AdaptiveTaskManifest) -> String {
        return orderSetPlanBucket(item.netLoad())
    }
}
