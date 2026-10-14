import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingInteractionSegmentsForCheckpoint(_ items: [RollingInteractionSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveSeasonalInteractionCheckpointsFromSegment(_ items: [RollingInteractionSegment]) -> [SeasonalInteractionCheckpoint] {
        var out: [SeasonalInteractionCheckpoint] = []
        for item in items {
            let derived = newSeasonalInteractionCheckpoint(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveSeasonalInteractionCheckpoint(_ item: SeasonalInteractionCheckpoint) -> Double {
        return legacyInteractionForecastWeight(6, active: true)
    }
}
