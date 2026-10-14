import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRollingTaskLedgersForCheckpoint(_ items: [RollingTaskLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveSeasonalRoundingCheckpointsFromLedger(_ items: [RollingTaskLedger]) -> [SeasonalRoundingCheckpoint] {
        var out: [SeasonalRoundingCheckpoint] = []
        for item in items {
            let derived = newSeasonalRoundingCheckpoint(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankSeasonalRoundingCheckpoint(_ item: SeasonalRoundingCheckpoint) -> Double {
        return defaultTaskRecordWeight(4, active: true)
    }
}
