import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRegionalProxyBaselinesForBatch(_ items: [RegionalProxyBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveRevocationBatchesFromBaseline(_ items: [RegionalProxyBaseline]) -> [RevocationBatch] {
        var out: [RevocationBatch] = []
        for item in items {
            let derived = newRevocationBatch(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyRevocationBatchExtra(_ item: RevocationBatch) -> String {
        return normalizePrimaryProxyCheckpointCode(item.code)
    }
}
