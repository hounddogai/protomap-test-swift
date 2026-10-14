import AcmePlatform
import Foundation

extension Consent {
    static func summarizeFallbackRevocationSnapshotsForBatch(_ items: [FallbackRevocationSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveWitnessBatchesFromSnapshot(_ items: [FallbackRevocationSnapshot]) -> [WitnessBatch] {
        var out: [WitnessBatch] = []
        for item in items {
            let derived = newWitnessBatch(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateWitnessBatch(_ item: WitnessBatch) -> String {
        return normalizeFallbackRevocationSnapshotCode(item.code)
    }
}
