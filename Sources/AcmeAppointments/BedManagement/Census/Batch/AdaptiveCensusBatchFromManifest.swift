import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationManifestsForBatch(_ items: [IsolationManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveAdaptiveCensusBatchesFromManifest(_ items: [IsolationManifest]) -> [AdaptiveCensusBatch] {
        var out: [AdaptiveCensusBatch] = []
        for item in items {
            let derived = newAdaptiveCensusBatch(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planAdaptiveCensusBatch(_ item: AdaptiveCensusBatch) -> String {
        return classifyIsolationMetric(item.effectiveLoad())
    }
}
