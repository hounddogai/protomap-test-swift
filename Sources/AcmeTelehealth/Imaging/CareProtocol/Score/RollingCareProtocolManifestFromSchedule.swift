import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeScheduledCareProtocolSchedulesForManifest(_ items: [ScheduledCareProtocolSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveRollingCareProtocolManifestsFromSchedule(_ items: [ScheduledCareProtocolSchedule]) -> [RollingCareProtocolManifest] {
        var out: [RollingCareProtocolManifest] = []
        for item in items {
            let derived = newRollingCareProtocolManifest(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRollingCareProtocolManifest(_ item: RollingCareProtocolManifest) -> String {
        return normalizeScheduledCareProtocolScheduleCode(item.code)
    }
}
