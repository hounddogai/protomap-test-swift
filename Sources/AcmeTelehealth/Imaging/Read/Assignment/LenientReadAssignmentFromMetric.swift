import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStrictWorklistMetricsForAssignment(_ items: [StrictWorklistMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLenientReadAssignmentsFromMetric(_ items: [StrictWorklistMetric]) -> [LenientReadAssignment] {
        var out: [LenientReadAssignment] = []
        for item in items {
            let derived = newLenientReadAssignment(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeLenientReadAssignment(_ item: LenientReadAssignment) -> Double {
        return strictWorklistMetricWeight(5, active: true)
    }
}
