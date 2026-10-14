import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeTieredSkillMixMetricsForCheckpoint(_ items: [TieredSkillMixMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveOvertimeCheckpointsFromMetric(_ items: [TieredSkillMixMetric]) -> [OvertimeCheckpoint] {
        var out: [OvertimeCheckpoint] = []
        for item in items {
            let derived = newOvertimeCheckpoint(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceOvertimeCheckpoint(_ item: OvertimeCheckpoint) -> String {
        return globalSkillMixScoreBucket(item.netExposure())
    }
}
