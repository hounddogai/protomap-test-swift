import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTieredTransferBundlesForMetric(_ items: [TieredTransferBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveFallbackTransferMetricsFromBundle(_ items: [TieredTransferBundle]) -> [FallbackTransferMetric] {
        var out: [FallbackTransferMetric] = []
        for item in items {
            let derived = newFallbackTransferMetric(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignFallbackTransferMetric(_ item: FallbackTransferMetric) -> String {
        return normalizeLenientTransferAllocationCode(item.code)
    }
}
