import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedAccessionMetricsForMilestone(_ items: [CappedAccessionMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveLenientSpecimenMilestonesFromMetric(_ items: [CappedAccessionMetric]) -> [LenientSpecimenMilestone] {
        var out: [LenientSpecimenMilestone] = []
        for item in items {
            let derived = newLenientSpecimenMilestone(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLenientSpecimenMilestone(_ item: LenientSpecimenMilestone) -> Double {
        return regionalAccessionScheduleWeight(4, active: true)
    }
}
