import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeDefaultAlertProfilesForBatch(_ items: [DefaultAlertProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveFallbackOrderSetBatchesFromProfile(_ items: [DefaultAlertProfile]) -> [FallbackOrderSetBatch] {
        var out: [FallbackOrderSetBatch] = []
        for item in items {
            let derived = newFallbackOrderSetBatch(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeFallbackOrderSetBatch(_ item: FallbackOrderSetBatch) -> Double {
        return alertVarianceWeight(3, active: true)
    }
}
