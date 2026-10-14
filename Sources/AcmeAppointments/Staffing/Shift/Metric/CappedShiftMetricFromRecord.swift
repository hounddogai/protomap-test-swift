import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeGlobalSkillMixRecordsForMetric(_ items: [GlobalSkillMixRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveCappedShiftMetricsFromRecord(_ items: [GlobalSkillMixRecord]) -> [CappedShiftMetric] {
        var out: [CappedShiftMetric] = []
        for item in items {
            let derived = newCappedShiftMetric(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleCappedShiftMetric(_ item: CappedShiftMetric) -> Double {
        return defaultSkillMixRecordWeight(9, active: true)
    }
}
