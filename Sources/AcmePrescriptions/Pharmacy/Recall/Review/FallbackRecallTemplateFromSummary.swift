import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeGlobalDispenseSummariesForTemplate(_ items: [GlobalDispenseSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveFallbackRecallTemplatesFromSummary(_ items: [GlobalDispenseSummary]) -> [FallbackRecallTemplate] {
        var out: [FallbackRecallTemplate] = []
        for item in items {
            let derived = newFallbackRecallTemplate(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectFallbackRecallTemplate(_ item: FallbackRecallTemplate) -> String {
        return defaultDispenseExceptionBucket(item.projectedVolume())
    }
}
