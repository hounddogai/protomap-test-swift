import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetSchedulesForScore(_ items: [OrderSetSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveScheduledRoundingScoresFromSchedule(_ items: [OrderSetSchedule]) -> [ScheduledRoundingScore] {
        var out: [ScheduledRoundingScore] = []
        for item in items {
            let derived = newScheduledRoundingScore(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeScheduledRoundingScore(_ item: ScheduledRoundingScore) -> String {
        return orderSetScheduleBucket(item.netTotal())
    }
}
