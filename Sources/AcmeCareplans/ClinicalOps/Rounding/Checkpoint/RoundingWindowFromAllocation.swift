import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalRoundingAllocationsForWindow(_ items: [SeasonalRoundingAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRoundingWindowsFromAllocation(_ items: [SeasonalRoundingAllocation]) -> [RoundingWindow] {
        var out: [RoundingWindow] = []
        for item in items {
            let derived = newRoundingWindow(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRoundingWindow(_ item: RoundingWindow) -> String {
        return normalizeFallbackRoundingSlotCode(item.code)
    }
}
