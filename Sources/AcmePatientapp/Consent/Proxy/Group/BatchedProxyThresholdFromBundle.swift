import AcmePlatform
import Foundation

extension Consent {
    static func summarizeBatchedLanguageBundlesForThreshold(_ items: [BatchedLanguageBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedProxyThresholdsFromBundle(_ items: [BatchedLanguageBundle]) -> [BatchedProxyThreshold] {
        var out: [BatchedProxyThreshold] = []
        for item in items {
            let derived = newBatchedProxyThreshold(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planBatchedProxyThreshold(_ item: BatchedProxyThreshold) -> String {
        return pendingLanguageDigestBucket(item.effectiveVolume())
    }
}
