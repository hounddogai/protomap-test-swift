import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeScheduledAlertSchedulesForTier(_ items: [ScheduledAlertSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveStrictOrderSetTiersFromSchedule(_ items: [ScheduledAlertSchedule]) -> [StrictOrderSetTier] {
        var out: [StrictOrderSetTier] = []
        for item in items {
            let derived = newStrictOrderSetTier(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignStrictOrderSetTier(_ item: StrictOrderSetTier) -> String {
        return normalizeRegionalAlertMetricCode(item.code)
    }
}
