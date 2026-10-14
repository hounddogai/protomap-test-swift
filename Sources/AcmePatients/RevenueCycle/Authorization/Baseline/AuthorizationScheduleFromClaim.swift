import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeScheduledDenialClaimsForSchedule(_ items: [ScheduledDenialClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAuthorizationSchedulesFromClaim(_ items: [ScheduledDenialClaim]) -> [AuthorizationSchedule] {
        var out: [AuthorizationSchedule] = []
        for item in items {
            let derived = newAuthorizationSchedule(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectAuthorizationSchedule(_ item: AuthorizationSchedule) -> String {
        return scheduledDenialClaimBucket(item.projectedTotal())
    }
}
