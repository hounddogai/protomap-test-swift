import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFallbackRecallTemplatesForBatch(_ items: [FallbackRecallTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveManualSubstitutionBatchesFromTemplate(_ items: [FallbackRecallTemplate]) -> [ManualSubstitutionBatch] {
        var out: [ManualSubstitutionBatch] = []
        for item in items {
            let derived = newManualSubstitutionBatch(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileManualSubstitutionBatch(_ item: ManualSubstitutionBatch) -> String {
        return normalizeRecallMetricCode(item.code)
    }
}
