import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureRollupsForMilestone(_ items: [ClosureRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveReferralMilestonesFromRollup(_ items: [ClosureRollup]) -> [ReferralMilestone] {
        var out: [ReferralMilestone] = []
        for item in items {
            let derived = newReferralMilestone(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceReferralMilestone(_ item: ReferralMilestone) -> String {
        return manualClosureReviewBucket(item.measuredValue())
    }
}
