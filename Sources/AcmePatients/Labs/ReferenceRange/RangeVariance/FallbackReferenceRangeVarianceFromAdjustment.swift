import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelAdjustmentsForVariance(_ items: [PanelAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveFallbackReferenceRangeVariancesFromAdjustment(_ items: [PanelAdjustment]) -> [FallbackReferenceRangeVariance] {
        var out: [FallbackReferenceRangeVariance] = []
        for item in items {
            let derived = newFallbackReferenceRangeVariance(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleFallbackReferenceRangeVarianceExtra(_ item: FallbackReferenceRangeVariance) -> Double {
        return manualPanelAllocationWeight(4, active: true)
    }
}
