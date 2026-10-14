import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionMetricsForCheckpoint(_ items: [AccessionMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveCappedAccessionCheckpointsFromMetric(_ items: [AccessionMetric]) -> [CappedAccessionCheckpoint] {
        var out: [CappedAccessionCheckpoint] = []
        for item in items {
            let derived = newCappedAccessionCheckpoint(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeCappedAccessionCheckpoint(_ item: CappedAccessionCheckpoint) -> Double {
        return accessionMetricWeight(3, active: true)
    }
}
