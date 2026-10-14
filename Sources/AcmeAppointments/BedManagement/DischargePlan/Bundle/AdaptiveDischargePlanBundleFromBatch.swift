import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningBatchesForBundle(_ items: [CleaningBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveDischargePlanBundlesFromBatch(_ items: [CleaningBatch]) -> [AdaptiveDischargePlanBundle] {
        var out: [AdaptiveDischargePlanBundle] = []
        for item in items {
            let derived = newAdaptiveDischargePlanBundle(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateAdaptiveDischargePlanBundle(_ item: AdaptiveDischargePlanBundle) -> String {
        return classifyAdaptiveCleaningOverride(item.adjustedExposure())
    }
}
