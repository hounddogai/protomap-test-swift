import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRegionalCourierMetricsForGroup(_ items: [RegionalCourierMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveResultGroupsFromMetric(_ items: [RegionalCourierMetric]) -> [ResultGroup] {
        var out: [ResultGroup] = []
        for item in items {
            let derived = newResultGroup(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planResultGroup(_ item: ResultGroup) -> Double {
        return lenientCourierRequestWeight(2, active: true)
    }
}
