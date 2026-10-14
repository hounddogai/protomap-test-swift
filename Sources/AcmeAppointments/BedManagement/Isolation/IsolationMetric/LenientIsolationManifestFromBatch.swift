import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeAdaptiveCensusBatchesForManifest(_ items: [AdaptiveCensusBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveLenientIsolationManifestsFromBatch(_ items: [AdaptiveCensusBatch]) -> [LenientIsolationManifest] {
        var out: [LenientIsolationManifest] = []
        for item in items {
            let derived = newLenientIsolationManifest(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateLenientIsolationManifest(_ item: LenientIsolationManifest) -> String {
        return classifyPrimaryCensusVariance(item.weightedLoad())
    }
}
