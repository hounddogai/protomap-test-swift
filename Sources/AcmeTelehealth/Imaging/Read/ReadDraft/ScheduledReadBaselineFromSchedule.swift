import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeReadSchedulesForBaseline(_ items: [ReadSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveScheduledReadBaselinesFromSchedule(_ items: [ReadSchedule]) -> [ScheduledReadBaseline] {
        var out: [ScheduledReadBaseline] = []
        for item in items {
            let derived = newScheduledReadBaseline(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeScheduledReadBaseline(_ item: ScheduledReadBaseline) -> Double {
        return tieredReadOverrideWeight(5, active: true)
    }
}
