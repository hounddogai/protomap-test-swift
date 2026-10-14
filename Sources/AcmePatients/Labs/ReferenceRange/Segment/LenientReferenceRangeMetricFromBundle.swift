import AcmePlatform
import Foundation

extension Labs {
    static func summarizeFallbackPanelBundlesForMetric(_ items: [FallbackPanelBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveLenientReferenceRangeMetricsFromBundle(_ items: [FallbackPanelBundle]) -> [LenientReferenceRangeMetric] {
        var out: [LenientReferenceRangeMetric] = []
        for item in items {
            let derived = newLenientReferenceRangeMetric(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectLenientReferenceRangeMetric(_ item: LenientReferenceRangeMetric) -> String {
        return classifyPanelForecast(item.projectedLoad())
    }
}
