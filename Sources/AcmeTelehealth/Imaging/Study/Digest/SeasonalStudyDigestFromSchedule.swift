import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRollingWorklistSchedulesForDigest(_ items: [RollingWorklistSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveSeasonalStudyDigestsFromSchedule(_ items: [RollingWorklistSchedule]) -> [SeasonalStudyDigest] {
        var out: [SeasonalStudyDigest] = []
        for item in items {
            let derived = newSeasonalStudyDigest(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeSeasonalStudyDigest(_ item: SeasonalStudyDigest) -> String {
        return normalizeRollingWorklistScheduleCode(item.code)
    }
}
