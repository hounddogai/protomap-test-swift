import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeScheduledAlertSchedulesForProfile(_ items: [ScheduledAlertSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveFallbackCareProtocolProfilesFromSchedule(_ items: [ScheduledAlertSchedule]) -> [FallbackCareProtocolProfile] {
        var out: [FallbackCareProtocolProfile] = []
        for item in items {
            let derived = newFallbackCareProtocolProfile(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignFallbackCareProtocolProfile(_ item: FallbackCareProtocolProfile) -> String {
        return classifyScheduledAlertSchedule(item.projectedTotal())
    }
}
