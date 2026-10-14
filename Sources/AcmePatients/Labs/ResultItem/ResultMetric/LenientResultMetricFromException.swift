import AcmePlatform
import Foundation

extension Labs {
    static func summarizeWeightedCourierExceptionsForMetric(_ items: [WeightedCourierException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveLenientResultMetricsFromException(_ items: [WeightedCourierException]) -> [LenientResultMetric] {
        var out: [LenientResultMetric] = []
        for item in items {
            let derived = newLenientResultMetric(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreLenientResultMetric(_ item: LenientResultMetric) -> Double {
        return globalCourierMilestoneWeight(6, active: true)
    }
}
