import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeScheduledSlotRecordsForBaseline(_ items: [ScheduledSlotRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveTieredFollowUpBaselinesFromRecord(_ items: [ScheduledSlotRecord]) -> [TieredFollowUpBaseline] {
        var out: [TieredFollowUpBaseline] = []
        for item in items {
            let derived = newTieredFollowUpBaseline(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyTieredFollowUpBaseline(_ item: TieredFollowUpBaseline) -> String {
        return classifySlotForecast(item.weightedTotal())
    }
}
