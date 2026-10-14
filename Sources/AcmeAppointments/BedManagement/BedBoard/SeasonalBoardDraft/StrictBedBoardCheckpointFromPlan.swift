import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeScheduledCleaningPlansForCheckpoint(_ items: [ScheduledCleaningPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveStrictBedBoardCheckpointsFromPlan(_ items: [ScheduledCleaningPlan]) -> [StrictBedBoardCheckpoint] {
        var out: [StrictBedBoardCheckpoint] = []
        for item in items {
            let derived = newStrictBedBoardCheckpoint(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyStrictBedBoardCheckpointExtra(_ item: StrictBedBoardCheckpoint) -> Double {
        return cappedCleaningScoreWeight(6, active: true)
    }
}
