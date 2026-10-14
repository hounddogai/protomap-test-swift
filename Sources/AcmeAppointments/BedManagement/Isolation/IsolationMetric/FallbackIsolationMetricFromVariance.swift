import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationVariancesForMetric(_ items: [IsolationVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveFallbackIsolationMetricsFromVariance(_ items: [IsolationVariance]) -> [FallbackIsolationMetric] {
        var out: [FallbackIsolationMetric] = []
        for item in items {
            let derived = newFallbackIsolationMetric(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankFallbackIsolationMetric(_ item: FallbackIsolationMetric) -> String {
        return normalizeIsolationManifestCode(item.code)
    }
}
