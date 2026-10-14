import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingRoundingWindowsForTier(_ items: [PendingRoundingWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveFallbackOrderSetTiersFromWindow(_ items: [PendingRoundingWindow]) -> [FallbackOrderSetTier] {
        var out: [FallbackOrderSetTier] = []
        for item in items {
            let derived = newFallbackOrderSetTier(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeFallbackOrderSetTier(_ item: FallbackOrderSetTier) -> String {
        return normalizePendingRoundingWindowCode(item.code)
    }
}
