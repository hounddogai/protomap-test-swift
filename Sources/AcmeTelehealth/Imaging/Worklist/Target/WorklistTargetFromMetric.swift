import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictWorklistMetricsForTarget(_ items: [StrictWorklistMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveWorklistTargetsFromMetric(_ items: [StrictWorklistMetric]) -> [WorklistTarget] {
        var out: [WorklistTarget] = []
        for item in items {
            let derived = newWorklistTarget(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planWorklistTarget(_ item: WorklistTarget) -> Double {
        return strictWorklistMetricWeight(1, active: true)
    }
}
