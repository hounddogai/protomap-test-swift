import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralAuditsForSchedule(_ items: [ReferralAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFollowUpSchedulesFromAudit(_ items: [ReferralAudit]) -> [FollowUpSchedule] {
        var out: [FollowUpSchedule] = []
        for item in items {
            let derived = newFollowUpSchedule(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileFollowUpSchedule(_ item: FollowUpSchedule) -> Double {
        return referralPlanWeight(9, active: true)
    }
}
