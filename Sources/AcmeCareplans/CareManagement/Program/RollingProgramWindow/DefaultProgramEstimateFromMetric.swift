import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeManualCareGapMetricsForEstimate(_ items: [ManualCareGapMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveDefaultProgramEstimatesFromMetric(_ items: [ManualCareGapMetric]) -> [DefaultProgramEstimate] {
        var out: [DefaultProgramEstimate] = []
        for item in items {
            let derived = newDefaultProgramEstimate(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeDefaultProgramEstimate(_ item: DefaultProgramEstimate) -> String {
        return careGapTemplateBucket(item.measuredValue())
    }
}
