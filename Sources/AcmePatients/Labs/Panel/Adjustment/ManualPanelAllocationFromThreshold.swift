import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackAccessionThresholdsForAllocation(_ items: [FallbackAccessionThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveManualPanelAllocationsFromThreshold(_ items: [FallbackAccessionThreshold]) -> [ManualPanelAllocation] {
        var out: [ManualPanelAllocation] = []
        for item in items {
            let derived = newManualPanelAllocation(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateManualPanelAllocation(_ item: ManualPanelAllocation) -> String {
        return normalizeSeasonalAccessionForecastCode(item.code)
    }
}
