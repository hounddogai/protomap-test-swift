import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedChargeEntriesForManifest(_ items: [BatchedChargeEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveCappedDenialManifestsFromEntry(_ items: [BatchedChargeEntry]) -> [CappedDenialManifest] {
        var out: [CappedDenialManifest] = []
        for item in items {
            let derived = newCappedDenialManifest(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computeCappedDenialManifest(_ item: CappedDenialManifest) -> String {
        return regionalChargeMetricBucket(item.weightedValue())
    }
}
