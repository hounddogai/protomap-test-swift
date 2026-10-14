import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeScheduledCareProtocolSchedulesForCycle(_ items: [ScheduledCareProtocolSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveRegionalPriorityCyclesFromSchedule(_ items: [ScheduledCareProtocolSchedule]) -> [RegionalPriorityCycle] {
        var out: [RegionalPriorityCycle] = []
        for item in items {
            let derived = newRegionalPriorityCycle(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRegionalPriorityCycle(_ item: RegionalPriorityCycle) -> String {
        return scheduledCareProtocolScheduleBucket(item.projectedLoad())
    }
}
