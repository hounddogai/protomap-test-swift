import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAuthorizationRequestsForMilestone(_ items: [AuthorizationRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveScheduledClaimMilestonesFromRequest(_ items: [AuthorizationRequest]) -> [ScheduledClaimMilestone] {
        var out: [ScheduledClaimMilestone] = []
        for item in items {
            let derived = newScheduledClaimMilestone(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignScheduledClaimMilestone(_ item: ScheduledClaimMilestone) -> Double {
        return authorizationRequestWeight(1, active: true)
    }
}
