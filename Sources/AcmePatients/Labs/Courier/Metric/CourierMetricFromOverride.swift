import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedResultOverridesForMetric(_ items: [CappedResultOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveCourierMetricsFromOverride(_ items: [CappedResultOverride]) -> [CourierMetric] {
        var out: [CourierMetric] = []
        for item in items {
            let derived = newCourierMetric(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveCourierMetric(_ item: CourierMetric) -> Double {
        return resultSlotWeight(4, active: true)
    }
}
