import AcmePlatform
import Foundation

extension Consent {
    static func summarizeProxyVariancesForDraft(_ items: [ProxyVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveWitnessDraftsFromVariance(_ items: [ProxyVariance]) -> [WitnessDraft] {
        var out: [WitnessDraft] = []
        for item in items {
            let derived = newWitnessDraft(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceWitnessDraft(_ item: WitnessDraft) -> String {
        return classifyProxyMetric(item.weightedExposure())
    }
}
