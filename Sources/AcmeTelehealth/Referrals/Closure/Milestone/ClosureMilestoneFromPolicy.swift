import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpPoliciesForMilestone(_ items: [FollowUpPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveClosureMilestonesFromPolicy(_ items: [FollowUpPolicy]) -> [ClosureMilestone] {
        var out: [ClosureMilestone] = []
        for item in items {
            let derived = newClosureMilestone(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchClosureMilestone(_ item: ClosureMilestone) -> Double {
        return followUpMappingWeight(6, active: true)
    }
}
