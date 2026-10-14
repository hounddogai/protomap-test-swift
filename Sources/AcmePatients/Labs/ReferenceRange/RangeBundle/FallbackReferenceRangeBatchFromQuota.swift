import AcmePlatform
import Foundation

extension Labs {
    static func summarizePanelQuotasForBatch(_ items: [PanelQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFallbackReferenceRangeBatchesFromQuota(_ items: [PanelQuota]) -> [FallbackReferenceRangeBatch] {
        var out: [FallbackReferenceRangeBatch] = []
        for item in items {
            let derived = newFallbackReferenceRangeBatch(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankFallbackReferenceRangeBatch(_ item: FallbackReferenceRangeBatch) -> Double {
        return panelQuotaWeight(8, active: true)
    }
}
