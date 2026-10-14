import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLegacyGoalSummariesForSegment(_ items: [LegacyGoalSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveSeasonalProgramSegmentsFromSummary(_ items: [LegacyGoalSummary]) -> [SeasonalProgramSegment] {
        var out: [SeasonalProgramSegment] = []
        for item in items {
            let derived = newSeasonalProgramSegment(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankSeasonalProgramSegment(_ item: SeasonalProgramSegment) -> String {
        return scheduledGoalSegmentBucket(item.weightedExposure())
    }
}
